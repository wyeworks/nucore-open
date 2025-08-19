# frozen_string_literal: true

namespace :schedule_rule do
  # This task is useful for switching a school over to PriceGroupDiscounts. If a
  # school is already using price group discounts on all its schedule rules, this
  # task will do nothing
  desc "Adds PriceGroupDiscounts for existing global price groups to every schedule rule"
  task add_price_group_discounts: :environment do |_t, _args|
    price_groups = PriceGroup.globals

    ScheduleRule.all.find_each do |schedule_rule|
      if schedule_rule.price_group_discounts.present?
        puts "Skipping schedule rule #{schedule_rule.id}, already has price_group_discounts"
      else
        price_groups.each_with_index do |price_group, _i|
          schedule_rule.price_group_discounts.create(
            price_group:,
            discount_percent: schedule_rule.discount_percent
          )
        end

        puts "Created price_group_discounts for #{schedule_rule.id}"
      end
    end
  end

  # Usage:
  # Dry run: rake "schedule_rule:add_missing_price_group_discounts[0]"
  # Commit: rake "schedule_rule:add_missing_price_group_discounts[0,true]"
  #
  # You can skip the discount_percent argument to use existing legacy discounts if they exist
  # Dry run: rake "schedule_rule:add_missing_price_group_discounts[,]"
  # Commit: rake "schedule_rule:add_missing_price_group_discounts[,true]"
  desc "Adds missing global price groups to existing schedule rules"
  task :add_missing_price_group_discounts, [:discount_percent, :commit] => :environment do |_t, args|
    discount_percent = args[:discount_percent]
    puts "Discount percent: #{discount_percent}"
    puts "Discount percent set to nil - this will attempt to use existing legacy discounts" if discount_percent.nil?
    commit = args[:commit] == "true"
    # if the schedule rule is missing, add it to the hash empty array values
    missing = Hash.new { |hash, key| hash[key] = { price_groups: [], previous: [] } }
    if commit
      PriceGroup.globals.each { |pg| pg.setup_schedule_rules(discount_percent:) }
    else
      ScheduleRule.all.find_each do |schedule_rule|
        PriceGroup.globals.each do |price_group|
          next if schedule_rule.price_group_discounts.find_by(price_group_id: price_group.id)

          missing[schedule_rule.id][:price_groups] << price_group.name
          missing[schedule_rule.id][:previous] << "#{price_group.name} - #{schedule_rule.discount_percent}" unless schedule_rule.discount_percent == discount_percent.to_f
        end
      end
      puts "Missing Price Groups:"
      puts missing.values.pluck(:price_groups).flatten.uniq
      changes = missing.map do |key, data|
        data[:previous].present? ? "#{key}: #{data[:previous].compact.join(", ")}" : nil
      end
      puts "Missing price_group_discount for #{missing.count} schedule rules."
      puts "#{changes.count} schedule rules would have their discount_percent changed."
      puts "Existing legacy discount values:"
      changes.compact.map { |change| puts change }
    end

  end
end
