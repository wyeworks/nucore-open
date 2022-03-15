# frozen_string_literal: true

namespace :price_policies do

  desc "Duplicate the newest price policies for a facility's services to the current fiscal year"
  task :duplicate_to_current_fiscal_year, [:url_name] => :environment do |_t, args|
    facility = Facility.find_by!(url_name: args[:url_name])

    facility.services.not_archived.each do |service|
      service.price_policies.newest.each do |price_policy|
        next unless price_policy.expired? # Don't duplicate a current policy

        new_price_policy = price_policy.dup
        new_price_policy.start_date = SettingsHelper.fiscal_year_beginning
        new_price_policy.expire_date = SettingsHelper.fiscal_year_end
        new_price_policy.save!
      end
    end
  end

  # bundle exec rake 'price_policies:update_usage_rate'
  # bundle exec rake 'price_policies:update_usage_rate[commit]'
  desc "Update current price policies that have usage_rate"
  task :update_usage_rate, [:commit] => :environment do |_t, args|
    commit = args[:commit].to_s == "commit"

    policies = PricePolicy.current.where.not(usage_rate: nil)

    puts "Updating #{policies.count} price rules ..."
    policies.each do |policy|
      if policy.usage_rate.nil? || policy.usage_subsidy.nil?
        puts "Skipped #{policy.id}"
      else
        puts policy.id
        puts "Before: #{policy.usage_rate.to_f}/#{policy.usage_subsidy.to_f}"
        puts "#{policy.hourly_usage_rate}/#{policy.hourly_usage_subsidy}"
        policy.usage_rate = policy.hourly_usage_rate.to_f.round(2)
        policy.usage_subsidy = policy.hourly_usage_subsidy.to_f.round(2)
        success = commit ? policy.save : policy.valid?
        puts "Errors: #{policy.errors.full_messages}" if !success
        puts "After: #{policy.usage_rate.to_f}/#{policy.usage_subsidy.to_f}"
        puts "#{policy.hourly_usage_rate}/#{policy.hourly_usage_subsidy}"
      end
    end; nil
    puts "DONE"
  end

end
