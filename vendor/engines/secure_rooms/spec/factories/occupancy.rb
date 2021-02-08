# frozen_string_literal: true

FactoryBot.define do
  factory :occupancy, class: SecureRooms::Occupancy do
    secure_room
    user

    trait :active do
      with_entry
    end

    trait :orphan do
      with_entry
      orphaned_at { Time.current }
    end

    trait :complete do
      with_entry
      with_exit
    end

    trait :with_entry do
      entry_event { create(:event, occurred_at: Time.current) }
      entry_at { entry_event.occurred_at }
    end

    trait :with_exit do
      exit_event { create(:event, occurred_at: Time.current + 2.hours) }
      exit_at { exit_event.occurred_at }
    end

    trait :with_order_detail do
      association :secure_room, :with_schedule_rule, :with_base_price
      order_detail { FactoryBot.create(:setup_order, product: secure_room, user: user, account: account).order_details.first }

      after(:create) do |occupancy|
        ProductUser.find_or_create_by!(user: occupancy.user, product: occupancy.secure_room, approved_by: 0)
        occupancy.order_detail.order.validate_order!
        occupancy.order_detail.order.purchase!

        occupancy.order_detail.backdate_to_complete! occupancy.exit_at if occupancy.exit_at?
      end
    end

    trait :problem_with_order_detail do
      orphan
      with_order_detail

      after(:create) do |occupancy|
        occupancy.order_detail.complete!
      end
    end
  end
end
