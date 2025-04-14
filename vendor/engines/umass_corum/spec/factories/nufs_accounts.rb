# frozen_string_literal: true

FactoryBot.modify do
  factory :nufs_account do
    # Sequence defined in speed_type_accounts
    account_number { generate(:speed_type_account_number) }

    after(:build) do |account, _evaluator|
      create(:api_speed_type, speed_type: account.account_number)
    end
  end
end
