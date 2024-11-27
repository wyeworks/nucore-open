# frozen_string_literal: true

FactoryBot.define do
  factory :schedule_rule do
    start_hour { 9 }
    start_min { 00 }
    end_hour { 17 }
    end_min { 00 }
    on_sun { true }
    on_mon { true }
    on_tue { true }
    on_wed { true }
    on_thu { true }
    on_fri { true }
    on_sat { true }

    transient do
      # this column is now deprecated, but it's
      # useful to pass in a single value when setting up specs
      discount_percent { 0.00 }
    end

    trait :weekday do
      on_sun { false }
      on_sat { false }
    end

    trait :weekend do
      on_sun { true }
      on_mon { false }
      on_tue { false }
      on_wed { false }
      on_thu { false }
      on_fri { false }
      on_sat { true }
    end

    trait :all_day do
      start_hour { 0 }
      end_hour { 24 }
    end

    trait :evening do
      start_hour { 17 }
      end_hour { 24 }
    end

    trait :unavailable do
      on_sun { false }
      on_mon { false }
      on_tue { false }
      on_wed { false }
      on_thu { false }
      on_fri { false }
      on_sat { false }
    end

    trait :with_setup_product do
      product { create(:setup_instrument, skip_schedule_rules: true) }
    end

    factory :weekend_schedule_rule do
      weekend
    end

    factory :all_day_schedule_rule do
      all_day
    end

    after(:build) do |schedule_rule, evaluator|
      if evaluator.discount_percent
        PriceGroup.globals.each do |price_group|
          schedule_rule.price_group_discounts.build(price_group: price_group, discount_percent: evaluator.discount_percent)
        end
      end
    end

    after(:create) do |schedule_rule, evaluator|
      evaluator.product.schedule_rules << schedule_rule if evaluator.product
    end
  end
end
