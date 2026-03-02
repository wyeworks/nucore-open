# frozen_string_literal: true

FactoryBot.define do
  sequence :test_account_number do |n|
    format("%s-%06d", TestAccount::NUMBER_PREFIX, n)
  end

  factory :test_account do
    account_number { generate(:test_account_number) }
    description { "Some account description" }

    trait :with_account_owner do
      transient do
        owner { create(:user) }
      end

      callback(:after_build) do |account, evaluator|
        account.account_users = account.account_users.reject(&:owner?)
        account.account_users << build(:account_user, user: evaluator.owner)
      end
    end
  end

end
