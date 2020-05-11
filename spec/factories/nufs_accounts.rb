# frozen_string_literal: true

overridable_factory :nufs_account do
  sequence(:account_number, "0000000") do |n|
    "999-#{n}" # fund3-dept7
  end

  sequence(:description, "aaaaaaaa") { |n| "nufs account #{n}" }
  expires_at { Time.zone.now + 1.month }
  created_by { 0 }
end

FactoryBot.modify do
  factory :nufs_account do
    transient do
      facility { nil }
    end

    after(:build) do |account, evaluator|
      account.facilities << evaluator.facility if evaluator.facility
    end
  end
end

FactoryBot.define do
  factory :setup_account, class: NufsAccount, parent: :nufs_account do
    transient do
      owner { create(:user) }
    end

    account_users_attributes { account_users_attributes_hash(user: owner) }

    after(:build) do |model|
      define_open_account "42345", model.account_number
    end
  end
end
