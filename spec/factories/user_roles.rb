# frozen_string_literal: true

FactoryBot.define do
  factory :user_role do
    facility
    user

    trait :facility_staff do
      role { UserRole::FACILITY_STAFF }
    end

    trait :global_admin do
      facility { nil }
      role { UserRole::ADMINISTRATOR }
    end
  end
end
