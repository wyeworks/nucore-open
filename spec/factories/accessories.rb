FactoryGirl.define do
  factory :instrument_with_accessory, parent: :setup_instrument do
    transient do
      accessory { create :setup_item, facility: facility }
    end

    after(:create) do |instrument, evaluator|
      instrument.accessories << evaluator.accessory
    end
  end

  factory :accessory, parent: :setup_item do
    transient do
      parent { create :setup_instrument, facility: facility }
      scaling_type "quantity"
    end

    after(:create) do |item, evaluator|
      evaluator.parent.product_accessories.create(accessory: item, scaling_type: evaluator.scaling_type)
    end
  end
end
