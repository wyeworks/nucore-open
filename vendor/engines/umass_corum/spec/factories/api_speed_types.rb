# frozen_string_literal: true

FactoryBot.define do
  factory :api_speed_type, class: UmassCorum::ApiSpeedType do
    # If we build more than 1 million over the course of the test suite, ensure
    # that we still only use six characters so the format is valid
    sequence(:speed_type) { |n| format('%06d', n % 1_000_000) }

    # These attributes are based on an actual response from the API
    active { true }
    version { 0 }
    clazz { " " }
    dept_desc { "Vet/Animal Science-User,Owner" }
    dept_id { "A010400000" }
    fund_code { "11000" }
    fund_desc { "State Maintenance" }
    manager_hr_emplid { "10038224" }
    program_code { "B03" }
    project_desc { "National Multiple Sclerosis So" }
    project_id { "S17110000000118" }
    date_added { 1.year.ago }
    project_start_date { 1.year.ago }
    project_end_date { 1.year.from_now }

    transient do
      account_number { nil }
    end

    after(:build) do |account, evaluator|
      account.speed_type = evaluator.account_number if evaluator.account_number
    end

    # Recharge speed types do not have project/grant info attached to them
    trait :recharge do
      project_id { nil }
      project_desc { nil }
      program_code { "D06" }
      dept_desc { "IALS M2M" }
    end

    trait :expired do
      active { false }
      date_removed { 1.month.ago }
      project_end_date { 1.month.ago }
      error_desc { "Speed_type has expired" }
    end

    trait :not_valid_start_date do
      project_start_date { nil }
    end

    trait :not_valid_end_date do
      project_start_date { nil }
    end
  end
end
