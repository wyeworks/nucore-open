# frozen_string_literal: true

FactoryBot.define do
  factory :price_group_discount do
    price_group
    schedule_rule { build(:schedule_rule, :with_setup_product)}
    discount_percent { 0 }

    trait :blank do
      price_group { nil }
      schedule_rule { nil }
      discount_percent { nil }
    end
  end
end
