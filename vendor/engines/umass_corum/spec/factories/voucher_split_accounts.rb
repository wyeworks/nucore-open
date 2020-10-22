# frozen_string_literal: true

FactoryBot.define do
  factory :voucher_split_account, class: UmassCorum::VoucherSplitAccount do
    with_account_owner

    sequence(:account_number) { |n| "account_number_#{n}" }
    sequence(:description) { |n| "split account #{n}" }
    expires_at { Time.current + 1.month }
    created_by { 0 }

    transient do
      without_splits { false }
      primary_subaccount { nil }
    end

    # Leave this at the bottom of the factory.
    # Add valid splits if none exist and if transient `without_splits` is false.
    callback(:after_build) do |split_account, evaluator|
      if split_account.splits.empty? && !evaluator.without_splits
        primary_subaccount = evaluator.primary_subaccount || build(:credit_card_account, :with_account_owner)
        split_account.splits << build(:split, percent: 50, apply_remainder: false, parent_split_account: split_account, subaccount: primary_subaccount)
        split_account.splits << build(:split, percent: 50, apply_remainder: true, parent_split_account: split_account, subaccount: UmassCorum::VoucherAccount.instance)
      end
    end

  end
end
