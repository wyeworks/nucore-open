# frozen_string_literal: true

FactoryBot.define do
  factory :facility do
    sequence(:name, "AAAAAAAA") { |n| "Facility#{Facility.count + n.to_i}" }
    sequence(:email) { |n| "facility-#{Facility.count + n}@example.com" }
    sequence(:abbreviation) { |n| "FA#{Facility.count + (2 * n)}" }
    short_description { "Short Description" }
    description { "Facility Description" }
    is_active { true }
    sequence(:url_name) { |n| "facility#{Facility.count + (2 * n)}" }

    trait :with_image do
      file { Rack::Test::UploadedFile.new("spec/files/cern.jpeg", "image/jpeg") }
    end

    trait :with_order_notification do
      sequence(:order_notification_recipient) { |n| "orders#{Facility.count + n}@example.com" }
    end

    callback(:after_build) do |facility, builder|
      # debugger
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
