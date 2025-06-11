# frozen_string_literal: true

FactoryBot.define do
  factory :estimate do
    facility
    user
    price_group
    association :created_by_user, factory: :user
    description { "Test Estimate" }
    note { "This is a test estimate" }
    expires_at { 1.month.from_now }
  end

  factory :estimate_detail do
    estimate
    product
    quantity { 1 }
  end
end
