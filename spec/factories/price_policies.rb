# frozen_string_literal: true

FactoryBot.define do
  factory :instrument_price_policy do
    price_group
    charge_for { InstrumentPricePolicy::CHARGE_FOR[:reservation] }
    association :product, factory: :setup_instrument
    usage_rate { 10 / 60.0 }
    usage_subsidy { 0 }
    minimum_cost { 1 }
    can_purchase { true }
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(start_date) }
    note { "This is note" }
  end

  factory :instrument_usage_price_policy, parent: :instrument_price_policy do
    charge_for { InstrumentPricePolicy::CHARGE_FOR[:usage] }
  end

  factory :instrument_overage_price_policy, parent: :instrument_price_policy do
    charge_for { InstrumentPricePolicy::CHARGE_FOR[:overage] }
  end

  factory :item_price_policy do
    can_purchase { true }
    unit_cost { 1 }
    unit_subsidy { 0 }
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(start_date) }
    note { "This is note" }
  end

  factory :service_price_policy do
    can_purchase { true }
    unit_cost { 1 }
    unit_subsidy { 0 }
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(start_date) }
    note { "This is note" }
  end

  factory :timed_service_price_policy do
    usage_rate { 60.0 } # $1/minute
    usage_subsidy { 0 }
    minimum_cost { 1 }
    can_purchase { true }
    start_date { Time.zone.now.beginning_of_day }
    expire_date { PricePolicy.generate_expire_date(start_date) }
    note { "This is note" }
  end
end
