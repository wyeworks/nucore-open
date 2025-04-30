# frozen_string_literal: true

FactoryBot.define do
  # If we build more than 1 million over the course of the test suite, ensure
  # that we still only use six characters so the format is valid.
  # This is shared with FacilityAccount so that we don't have conflicting
  # Api records in the database coming from two different factories..
  sequence(:speed_type_account_number) { |n| format('%06d', n % 1_000_000) }

  factory :speed_type_account, parent: :account, class: UmassCorum::SpeedTypeAccount do
    type { "UmassCorum::SpeedTypeAccount" }
    account_number { generate(:speed_type_account_number) }

    trait :with_api_speed_type do
      after(:build) do |account, _evaluator|
        if account.expired?
          create(:api_speed_type, :expired, speed_type: account.account_number)
        else
          create(:api_speed_type, speed_type: account.account_number)
        end
      end
    end
  end
end
