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

  desc "Retouch all complete order details and recalculate pricing"
  task :recalculate_prices, [:facility_slug] => :environment do |_t, _args|
    Facility.find_by(url_name: "path").order_details.where(state: "complete").each do |od|
      old_cost = od.actual_cost
      old_subsidy = od.actual_subsidy
      old_total = od.actual_total
      old_price_group = od.price_policy.try(:price_group)
      od.assign_price_policy
      puts "#{od}|#{od.order_status}|#{od.account}|#{od.user}|#{od.product}|#{od.fulfilled_at}|#{old_price_group}|#{old_cost}|#{old_subsidy}|#{old_total}|#{od.price_policy.try(:price_group)}|#{od.actual_cost}|#{od.actual_subsidy}|#{od.actual_total}|#{od.actual_total == old_total}"
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
  desc "Adds a template_result file to an order detail"
  task :add_template_result, [:id] => :environment do |_t, args|
    order_detail = OrderDetail.find args[:id]
    file = order_detail.product.stored_files.template.first.dup
    file.file_type = "template_result"
    order_detail.stored_files << file
    order_detail.save
  end
end
