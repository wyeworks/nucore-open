# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::AccountSearchReport, feature_setting: { account_tabs: false } do
  let(:facility) { build(:facility, name: "Single Facility", abbreviation: "SF") }
  let(:facility2) { build(:facility, name: "Other Facility", abbreviation: "OF") }
  let(:owner) { create(:user, first_name: "My", last_name: "Owner") }
  let(:account) do
    create(
      :account,
      :with_account_owner,
      account_number: "12345",
      description: "Testing",
      owner:,
      expires_at: Time.zone.parse("2020-01-01"),
    )
  end
  let(:suspended) do
    create(
      :account,
      :with_account_owner,
      account_number: "54321",
      description: "Testing Susp",
      owner:,
      suspended_at: Time.zone.parse("2019-12-01"),
      expires_at: Time.zone.parse("2020-01-02"),
    )
  end
  let(:multi_facility) do
    create(
      :account,
      :with_account_owner,
      account_number: "10001",
      facilities: [facility, facility2],
    )
  end

  let!(:accounts) { [account, suspended, multi_facility] }

  subject(:report) do
    described_class.new(
      search_term: "",
      facility: SerializableFacility.new(Facility.cross_facility),
      filter_params: {},
    )
  end

  it "has the right fields" do
    expect(report).to have_column_values(
      "Payment Source" => [anything, "Testing / 12345", "Testing Susp / 54321 (SUSPENDED)"],
      "Account Number" => [anything, "12345", "54321"],
      "Description" => [anything, "Testing", "Testing Susp"],
      "Suspended" => [anything, be_blank, "12/01/2019"],
      "Owner" => [anything, "My Owner", "My Owner"],
      "Expiration" => [anything, "01/01/2020", "01/02/2020"],
      "Facilities" => [anything, "All", "All"],
    )
  end
end
