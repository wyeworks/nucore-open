# frozen_string_literal: true

FactoryBot.define do
  factory :instrument_with_accessory, parent: :setup_instrument do
    transient do
      accessory { create :setup_item, facility: }
    end

    after(:create) do |instrument, evaluator|
      instrument.accessories << evaluator.accessory
    end
  end

  factory :accessory, parent: :setup_item do
    transient do
      parent { create :setup_instrument, facility: }
      scaling_type { "quantity" }
    end

    after(:create) do |item, evaluator|
      evaluator.parent.product_accessories.create(accessory: item, scaling_type: evaluator.scaling_type)
    end
  end

  factory :time_based_accessory, parent: :setup_timed_service do
    transient do
      parent { create :setup_instrument, facility: }
      scaling_type { "auto" }
    end

    after(:create) do |item, evaluator|
      evaluator.parent.product_accessories.create(accessory: item, scaling_type: evaluator.scaling_type)
    end
  end
end
