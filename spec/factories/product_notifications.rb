# frozen_string_literal: true

FactoryBot.define do
  factory :product_notification do
    facility
    notification_type { "slot_available" }
    sequence(:name) { |n| "Notification #{n}" }
  end
end
