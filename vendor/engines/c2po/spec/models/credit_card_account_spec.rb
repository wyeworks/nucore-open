# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreditCardAccount do
  let(:facility) { FactoryBot.create(:facility) }
  subject(:account) { FactoryBot.create(:credit_card_account, :with_account_owner, facility: facility) }

  include_examples "AffiliateAccount"
  include_examples "an Account"

  it "is a per-facility account" do
    expect(described_class).to be_per_facility
  end

  it "is not a global account" do
    expect(described_class).not_to be_global
  end

  it "has the facility association" do
    expect(account.facilities).to eq([facility])
  end
end
