# frozen_string_literal: true

namespace :reservations do
  desc "notify users with upcoming reservations for offline instruments"
  task notify_offline: :environment do
    UpcomingOfflineReservationNotifier.new.notify
  end

  desc "Move instruments from a shared schedule to their own new schedules"
  # Usage:
  # Dry run: rake reservations:shared_to_unshared[1234]
  # Commit: rake reservations:shared_to_unshared[1234,true]
  task :shared_to_unshared, [:product_id, :commit] => :environment do |_t, args|
    shared_schedule_product = Product.find(args[:product_id])
    if shared_schedule_product
      shared_schedule = shared_schedule_product.schedule
      # leave the existing shared schedule associated with the parent instrument,
      # which only exists to facilitate shared access to the room.
      to_unshare = shared_schedule.products.to_a - [shared_schedule_product]
      puts "Attempting to create new unshared schedules for #{to_unshare.count} products"
      # create new non-shared schedules for each of the other instruments.
      failed = []
      success = []
      to_unshare.each do |inst|
        inst.send(:create_default_schedule)
        if args[:commit]
          inst.save
        else
          inst.valid?
        end
        if inst.errors.any?
          failed << inst
        else
          success << inst
        end
      end
      puts "Moved #{success.count} instruments to a new unshared schedule:"
      success.map { |inst| puts "https://corum.umass.edu/facilities/#{inst.facility}/instruments/#{inst.url_name}/manage" }
      puts "#{failed.count} errors:"
      failed.map { |inst| puts "#{inst.url_name} - #{inst.errors.full_messages}" }
    else
      puts "Product not found"
    end
  end
end
