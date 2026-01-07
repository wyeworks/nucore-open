# frozen_string_literal: true

FactoryBot.define do
  sequence :test_account_number do |n|
    format("%s-%06d", TestAccount::NUMBER_PREFIX, n)
  end

  factory :test_account do
    account_number { generate(:test_account_number) }
  end
end
