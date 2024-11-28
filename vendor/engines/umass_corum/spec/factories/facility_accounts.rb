# frozen_string_literal: true

FactoryBot.modify do
  # Aka revenue account, aka recharge account
  factory :facility_account do
    # Sequence defined in speed_type_accounts
    account_number { generate(:speed_type_account_number) }

    before(:create) do |facility_account|
      create(:api_speed_type, speed_type: facility_account.account_number) unless UmassCorum::ApiSpeedType.find_by(speed_type: facility_account.account_number)
    end
  end
end
