# frozen_string_literal: true

FactoryBot.define do
  factory :credit_card_account, parent: :account, class: CreditCardAccount do
    type { "CreditCardAccount" }
    sequence(:account_number) { |_n| "5276-4400-6542-1319" }
    sequence(:description) { |n| "credit card account description #{n}" }
    name_on_card { "Person" }
    expiration_month { Time.zone.now.month }
    expiration_year { 1.year.from_now.year }
    expires_at { 1.month.from_now }
    sequence(:affiliate) { |n| Affiliate.find_or_create_by(name: "cc_affiliate#{n}") }
  end

  factory :purchase_order_account, parent: :account, class: PurchaseOrderAccount do
    type { "PurchaseOrderAccount" }
    sequence(:account_number, &:to_s)
    sequence(:description) { |n| "purchase order account description #{n}" }
    expires_at { 1.month.from_now }
    sequence(:affiliate) { |n| Affiliate.find_or_create_by(name: "po_affiliate#{n}") }
  end
end
