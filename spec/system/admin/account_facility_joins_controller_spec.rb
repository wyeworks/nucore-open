# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountFacilityJoinsController, feature_setting: { edit_accounts: true, multi_facility_accounts: true, reload_routes: true } do

  # Not all implementations have facility-specific account types, so build our own for this
  # set of specs.
  class PerFacilityTestAccount < Account
  end

  before do
    allow(Account.config).to receive(:facility_account_types).and_return(["PerFacilityTestAccount"])
    facility_specific_account.update!(type: "PerFacilityTestAccount")
  end

  let(:facility) { create(:facility) }
  let(:facility_specific_account) { create(:account, :with_account_owner, facility: facility) }
  let(:global_account) { create(:nufs_account, :with_account_owner) }

  describe "as a global admin" do
    let!(:facility2) { create(:facility) }
    before { login_as create(:user, :administrator) }

    it "can update the facilities" do
      visit edit_facility_account_account_facility_joins_path(facility, facility_specific_account)
      select facility2.to_s, from: "Facilities"
      click_button "Save"
      expect(page).to have_content("updated")
      expect(page).to have_select("Facilities", selected: [facility.to_s, facility2.to_s])
    end

    it "has an error if nothing is selected" do
      visit edit_facility_account_account_facility_joins_path(facility, facility_specific_account)
      unselect facility.to_s, from: "Facilities"
      click_button "Save"
      expect(page).to have_content "can't be blank"
    end

    it "errors if you're trying to remove it from the current facility" do
      visit edit_facility_account_account_facility_joins_path(facility, facility_specific_account)
      select facility2.to_s, from: "Facilities"
      unselect facility.to_s, from: "Facilities"
      click_button "Save"
      expect(page).to have_content "can't remove"
    end

    it "cannot visit a global account" do
      visit edit_facility_account_account_facility_joins_path(facility, global_account)
      expect(page).to have_content("Not Found")
    end
  end

  describe "as a facility admin" do
    before { login_as create(:user, :facility_administrator, facility: facility) }

    it "cannot access the page" do
      visit edit_facility_account_account_facility_joins_path(facility, facility_specific_account)
      expect(page).to have_content("Permission Denied")
    end
  end

  describe "as an account manager" do
    before { login_as create(:user, :account_manager) }

    it "cannot access the page" do
      visit edit_facility_account_account_facility_joins_path(facility, facility_specific_account)
      expect(page).to have_content("Permission Denied")
    end
  end
end
