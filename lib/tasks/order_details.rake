# frozen_string_literal: true

namespace :order_details do
  desc "mark order_details with past reservations as complete"
  task expire_reservations: :environment do
    AutoExpireReservation.new.perform
    EndReservationOnly.new.perform
  end

  desc "automatically switch off auto_logout instrument"
  task auto_logout: :environment do
    AutoLogout.new.perform
  end

  desc "task to remove merge orders that have been abandoned. See Task #48377"
  task remove_merge_orders: :environment do
    stale_merge_orders = Order.where("merge_with_order_id IS NOT NULL AND created_at <= ?", Time.zone.now - 4.weeks).includes(:order_details).all
    stale_merge_orders, failed_to_merge_orders = stale_merge_orders.partition { |order| order.order_details.empty? || order.order_details.all?(&:new?) }
    stale_merge_orders.each(&:destroy)
    if defined?(Rollbar) && failed_to_merge_orders.present?
      Rollbar.info("Stale merge orders have order details that are in process, completed, reconciled or canceled: #{failed_to_merge_orders.map(&:id)}")
    end
  end

  # bundle exec rake 'order_details:recalculate_prices[flow]'
  # bundle exec rake 'order_details:recalculate_prices[flow,commit]'
  desc "Retouch all complete order details and recalculate pricing"
  task :recalculate_prices, [:facility_url, :commit] => :environment do |_t, args|
    commit = args[:commit].to_s == "commit"
    facility = Facility.find_by!(url_name: args[:facility_url])
    # Change this query for when we need to recalculate prices for just a subset of Order details
    # Changes to this should be marked with the ticket number in the git commit message
    query = facility.order_details.where("fulfilled_at >= ? and fulfilled_at < ?",
                        Time.zone.local(2020, 9, 1), Time.zone.now.end_of_day)

    only_completed = query.where(state: "complete", journal_id: nil, statement_id: nil)
                          .joins(:order).where(orders: { state: "purchased" })

    only_completed.readonly(false).each do |od|
      old_cost = od.actual_cost
      old_subsidy = od.actual_subsidy
      old_total = od.actual_total
      old_price_group = od.price_policy.try(:price_group)
      old_price_policy = od.price_policy
      od.assign_price_policy

      # Change this guard clause depending on the use case
      next if od.price_policy.nil? || (od.price_policy == old_price_policy)

      od.save! if commit
      puts "#{od.facility.name}|#{od}|#{od.order_status}|#{od.account}|#{od.user}|#{od.product}|#{od.fulfilled_at}|#{old_price_group}|#{old_cost}|#{old_subsidy}|#{old_total}|#{od.price_policy.try(:price_group)}|#{od.actual_cost}|#{od.actual_subsidy}|#{od.actual_total}"
    end
  end

  desc "Uncancels a list of order details. The file should contain just the OD ID, one per line"
  task :uncancel, [:filename] => :environment do |_t, args|
    Rails.logger = Logger.new(STDOUT)
    uncanceler = OrderUncanceler.new
    File.open(args[:filename]).each_line do |line|
      order_detail = OrderDetail.find_by(id: line.chomp)
      if order_detail
        uncanceler.uncancel_to_complete(order_detail)
      else
        puts "Could not find order detail #{line}"
      end
    end
  end

  # In the case that a service is modified to require a form after it has been
  # purchased, the order detail will state that it's missing a form, but there's
  # no way to add the needed template_result file via the UI after purchase.
  # This task adds a template_result file to an order detail by copying the template
  # file from the product that was purchased.
  #
  # Example: `rake order_details:add_template_result["44 43"]`
  desc "Adds a template_result file to order details that are missing forms"
  task :add_template_result, [:ids] => :environment do |_t, args|
    order_details = OrderDetail.where id: args[:ids].split

    puts "Attempting to add missing files to order details..."

    order_details.each do |order_detail|
      next unless order_detail.missing_form?

      order_detail.stored_files << StoredFile.new(
        file: StringIO.new("Placeholder text for missing template."),
        file_type: "template_result",
        name: "placeholder.csv",
        created_by: order_detail.user.id,
      )

      puts "...missing file added to order detail #{order_detail.id}"

      order_detail.save
    end
  end

  # Use with caution.
  # This is _probably_ safe, especially in cases where the data to be cleaned up
  # is small; for example when onboarding a new university or lab facility.
  # If possible, take a data snapshot or ensure access to a backup before running this.
  desc "remove list of order details"
  task clean_up_orders: :environment do
    class OrderDetailCleaner

      def self.remove_order(order_detail)
        order = order_detail.order
        journal = order_detail.journal
        puts "need to check journal" if journal

        statement = order_detail.statement
        puts "need to check statement" if statement

        puts "destroying detail #{order_detail.id}"
        order_detail.destroy

        if order.order_details.empty?
          puts "destroying order #{order.id}"
          order.destroy
        end
      end

      def self.remove_orders(file)
        OrderDetail.transaction do
          File.open(file, "r").each_line do |line|
            next unless /([0-9]+)-([0-9]+)/ =~ line

            remove_order(OrderDetail.find(Regexp.last_match(2)))
          end
        end
        puts "Done"
      end

    end

    OrderDetailCleaner.remove_orders("lib/tasks/orders_to_remove.txt")
  end
end
