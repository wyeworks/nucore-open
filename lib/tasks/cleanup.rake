# frozen_string_literal: true

namespace :cleanup do
  namespace :accounts do
    desc "clean up accounts.expires_at column"
    task expires_at: :environment do
      Account.all.each do |a|
        AccountCleaner.clean_expires_at(a)
      end
    end
  end

  namespace :carts do
    desc "Cleans out abandoned carts (i.e. cart that have only an instrument order detail in them)"
    task destroy_abandoned: :environment do
      Rails.logger = Logger.new(STDOUT)
      Rails.logger.level = Logger::INFO
      Cart.destroy_all_instrument_only_carts(5.days.ago)
    end
  end

  namespace :price_groups do
    desc "remove cancer center"
    task :cancer_center, [:cancer_center_name] => :environment do |_t, args|
      cc_name = args[:cancer_center_name] || "Cancer Center Rate"
      pg = PriceGroup.find_by(name: cc_name)
      abort("No cancer center price group found with name #{cc_name}") unless pg

      pg.facility = Facility.first
      pg.destroy!
      puts "Price group with id: #{pg.id}, name: #{cc_name} has been destroyed."
    end
  end

  namespace :log_events do
    desc "update metadata for PriceGroupMembers"
    task metadata: :environment do
      events = LogEvent.where(loggable_type: "PriceGroupMember").where(metadata: nil)
      puts "Updating #{events.size} LogEvents..."
      events.find_each do |event|
        event.update(metadata: { member_type: event.loggable.member_type })
      end
    end
  end
end
