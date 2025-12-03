# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseOrderAccount do
  include TextHelpers
  include AccountsTestHelper

  let(:facility) { FactoryBot.create(:facility) }
  subject(:account) { FactoryBot.create(:purchase_order_account, :with_account_owner, facility: facility) }

  include_examples "AffiliateAccount"
  include_examples "an Account"

  context "when it's not global" do
    before do
      skip_if_account_global(:purchase_order)
    end

    it "is a per-facility account" do
      expect(described_class).to be_per_facility
    end

    it "is not a global account" do
      expect(described_class).not_to be_global
    end
  end

  it "includes the facility in the description" do
    expect(account.to_s).to include facility.name
  end

  it "has the facility association" do
    expect(account.facilities).to eq([facility])
  end

  it "rolls the facilities up in the description of there are more than one" do
    facility2 = FactoryBot.create(:facility)
    account.facilities << facility2
    expect(account.to_s).to include "2 #{Facility.model_name.human.pluralize}"
  end

  describe "monetary_cap validation" do
    context "when feature flag is enabled", feature_setting: { purchase_order_monetary_cap: true } do
      it "is valid with a positive monetary_cap" do
        account.monetary_cap = 1000.50
        expect(account).to be_valid
      end

      it "is valid with nil monetary_cap" do
        account.monetary_cap = nil
        expect(account).to be_valid
      end

      it "is invalid with negative monetary_cap" do
        account.monetary_cap = -100
        expect(account).not_to be_valid
        expect(account.errors[:monetary_cap]).to include("must be greater than 0")
      end
    end
  end
end
