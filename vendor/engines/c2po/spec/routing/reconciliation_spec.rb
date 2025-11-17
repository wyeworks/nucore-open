# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FacilityAccountsReconciliationController" do
  include AccountsTestHelper

  it "routes credit_cards" do
    skip_if_account_unreconcilable(:credit_card)

    expect(get("/#{facilities_route}/test-facility/accounts/credit_cards"))
      .to route_to(controller: "facility_accounts_reconciliation",
                   action: "index",
                   facility_id: "test-facility",
                   account_type: "CreditCardAccount")
  end

  it "routes purchase_orders" do
    skip_if_account_unreconcilable(:purchase_order)

    expect(get("/#{facilities_route}/test-facility/accounts/purchase_orders"))
      .to route_to(controller: "facility_accounts_reconciliation",
                   action: "index",
                   facility_id: "test-facility",
                   account_type: "PurchaseOrderAccount")
  end

  it "does not allow overriding the account_type" do
    # TODO: Remove 'pending' and test again after upgrading to Rails 4.1
    pending "Override does not appear to happen in console-generated requests"
    expect(get("/#{facilities_route}/test-facility/accounts/purchase_orders?account_type=CreditCardAccount"))
      .to route_to(controller: "facility_accounts_reconciliation",
                   action: "index",
                   facility_id: "test-facility",
                   account_type: "PurchaseOrderAccount")
  end
end
