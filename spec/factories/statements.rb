# frozen_string_literal: true

FactoryBot.define do
  factory :statement do
    association :account, factory: :setup_account
    association :created_by_user, factory: :user
    created_at { Time.zone.now }
    invoice_date { Time.current.to_date }
    facility
  end
end
