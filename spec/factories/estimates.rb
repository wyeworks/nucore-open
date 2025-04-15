# frozen_string_literal: true

FactoryBot.define do
  factory :estimate do
    facility
    user
    association :created_by_user, factory: :user
    name { "Test Estimate" }
    note { "This is a test estimate" }
    expires_at { 30.days.from_now }
  end
end
