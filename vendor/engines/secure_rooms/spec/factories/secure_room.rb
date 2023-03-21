# frozen_string_literal: true

FactoryBot.define do
  factory :secure_room, class: SecureRoom, parent: :setup_product do
    sequence(:name) { |n| "Room #{n}" }
    sequence(:url_name) { |n| "Room#{n}" }

    trait :with_schedule_rule do
      after(:create) do |room, _evaluator|
        room.schedule_rules << build(:schedule_rule)
      end
    end

    trait :with_base_price do
      after(:create) do |room, _evaluator|
        create(:secure_room_price_policy, price_group: PriceGroup.base, product: room)
      end
    end
  end
end
