# frozen_string_literal: true

FactoryBot.define do
  factory :split_account, class: SplitAccounts::SplitAccount, aliases: ["split_accounts/split_account"] do
    with_account_owner

    transient do
      without_splits { false } # set to true to skip generating a valid split
    end

    sequence(:account_number) { |n| "account_number_#{n}" }
    sequence(:description) { |n| "split account #{n}" }
    expires_at { Time.current + 1.month }
    created_by { 0 }

    trait :with_three_splits do
      callback(:after_build) do |split_account, _evalutor|
        split_account.splits << build(:split, percent: 33.33, apply_remainder: true, parent_split_account: split_account)
        split_account.splits << build(:split, percent: 33.33, apply_remainder: false, parent_split_account: split_account)
        split_account.splits << build(:split, percent: 33.34, apply_remainder: false, parent_split_account: split_account)
      end
    end

    # Leave this at the bottom of the factory.
    # Add valid splits if none exist and if transient `without_splits` is false.
    callback(:after_build) do |split_account, evaluator|
      unless split_account.splits.present? || evaluator.without_splits
        split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account)
        split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account)
      end
    end
  end
end
