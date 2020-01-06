# frozen_string_literal: true

FactoryBot.define do
  factory :api_speed_type, class: UmassCorum::ApiSpeedType do
    # If we build more than 1 million over the course of the test suite, ensure
    # that we still only use six characters so the format is valid
    sequence(:speed_type, "000000") { |n| format('%06d', (n % 1_000_000)) }

    # These attributes are based on an actual response from the API
    active { true }
    version { 0 }
    clazz { " " }
    dept_desc { "Vet/Animal Science" }
    dept_id { "A010400000" }
    fund_code { "11000" }
    fund_desc { "State  aintenance" }
    manager_hr_emplid { "10038224" }
    program_code { "B03" }
    project_desc { "National Multiple Sclerosis So" }
    project_id { "S17110000000118" }
    date_added { 1.year.ago }

    trait :expired do
      active { false }
      date_removed { 1.month.ago }
      error_desc { "Speed_type has expired" }
    end
  end
end
