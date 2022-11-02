# frozen_string_literal: true

FactoryBot.define do
  factory :facility do
    sequence(:name, "AAAAAAAA") { |n| "Facility#{n}" }
    sequence(:email) { |n| "facility-#{n}@example.com" }
    sequence(:abbreviation) { |n| "FA#{n}" }
    short_description { "Short Description" }
    description { "Facility Description" }
    is_active { true }
    sequence(:url_name) { |n| "facility#{n}" }

    trait :with_image do
      file { File.open("#{Rails.root}/spec/files/cern.jpeg") }
    end

    trait :with_order_notification do
      sequence(:order_notification_recipient) { |n| "orders#{n}@example.com" }
    end
  end

  factory :setup_facility, class: Facility, parent: :facility do
    after(:create) do |facility|
      FactoryBot.create(:facility_account, facility: facility)
      # user is_internal => false so that we can just use .last to access it
      FactoryBot.create(:price_group, facility: facility, is_internal: false)
    end
  end
end
