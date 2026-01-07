# frozen_string_literal: true

FactoryBot.define do
  sequence :test_account_number do |n|
    format("test-%06d", n)
  end

  factory :test_account do
    account_number { generate(:test_account_number) }
  end
end
