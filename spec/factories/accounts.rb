# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    type { "Account" }
    sequence(:account_number) { |n| n }
    description { "Account description" }
    expires_at { 50.years.from_now }
    created_by { 0 }

    transient do
      facility { nil }
    end

    after(:build) do |account, evaluator|
      account.facilities << evaluator.facility if evaluator.facility
    end
  end

  trait :with_account_owner do
    transient do
      owner { FactoryBot.create(:user) }
    end

    # Every account must have an account_user "owner" in order for the account
    # to be valid in rails. And foreign key constraints require that each
    # account_user has an account inserted before the account_user is inserted.
    callback(:after_build) do |account, evaluator|
      # Some subclass factories might already include this trait, so we don't want
      # to accidentally have two owners.
      account.account_users = account.account_users.reject(&:owner?)
      account.account_users << build(:account_user, user: evaluator.owner)
    end
  end

  trait :with_order do
    with_account_owner

    transient do
      product { nil }
    end

    account_users_attributes { [FactoryBot.attributes_for(:account_user, user: owner)] }

    after(:create) do |account, evaluator|
      order = FactoryBot.create(
        :order,
        user: evaluator.owner,
        created_by: evaluator.owner.id,
        facility: evaluator.product.facility,
      )

      FactoryBot.create(
        :order_detail,
        product: evaluator.product,
        order: order,
        account: account,
      )
    end
  end
end
