# frozen_string_literal: true

FactoryBot.define do
  factory :subsidy_account, parent: :account, class: UmassCorum::SubsidyAccount do
    type { "UmassCorum::SubsidyAccount" }
    expires_at { 5.years.from_now }
    description { "Subsidy account description" }
    account_number { nil }

    callback(:after_build) do |account, _evaluator|
      account.account_number = create(:speed_type_account, :with_account_owner, :with_api_speed_type).account_number unless account.account_number
    end
  end
end
