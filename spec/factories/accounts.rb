# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    type { "Account" }
    sequence(:account_number) { |n| n }
    description { "Account description" }
    expires_at { 50.years.from_now }
    created_by { 0 }
  end

  trait :with_account_owner do
    transient do
      owner { FactoryBot.create(:user) }
    end

    # Every account must have an account_user "owner" in order for the account
    # to be valid in rails. And foreign key constraints require that each
    # account_user has an account inserted before the account_user is inserted.
    callback(:after_build) do |account, evaluator|
      account.account_users << build(:account_user, user: evaluator.owner)
    end
  end
end
