require "rails_helper"

RSpec.describe "Managing recharge accounts (FacilityFacilityAccountsController)" do

  let(:facility) { FactoryBot.create(:facility) }
  let!(:director) { FactoryBot.create(:user, :facility_director, facility: facility) }
  let(:default_revenue_account) { Settings.accounts.revenue_account_default }
  let(:dummy_account) { build(:facility_account) }

  before do
    define_open_account default_revenue_account, dummy_account.account_number
    login_as director
    visit manage_facility_path(facility)
  end

  it "can create a recharge account" do
    click_link "Recharge Chart Strings"
    click_link "Add Recharge Chart String"

    # This is a somewhat convoluted way to fill out the form, but each school will
    # have different fields for their chart strings. E.g. NU has Fund, Department,
    # Project, etc. while the default just has a
    # Individual schools should implement a similar spec in their engine that
    # is more explicit in which fields it fills out.
    dummy_account.account_number_fields.each do |field, _values|
      if field == :account_number
        fill_in "Account Number", with: dummy_account.account_number
      else
        fill_in I18n.t("facility_account.account_fields.label.account_number.#{field}"), with: dummy_account.account_number_parts[field]
      end
    end

    click_button "Create"

    expect(page).to have_content("Recharge Chart String was successfully created")
    expect(page).to have_link(dummy_account.to_s)
  end

  describe "editing an existing" do
    let!(:facility_account) { FactoryBot.create(:facility_account, facility: facility) }

    it "cannot edit most fields, but can mark it as inactive" do
      click_link "Recharge Chart Strings"
      click_link facility_account.to_s

      dummy_account.account_number_fields.each do |field, _values|
        expect(page).to have_field(I18n.t(field, scope: "facility_account.account_fields.label.account_number"), readonly: true)
      end

      uncheck "Is Active?"
      click_button "Save"
      expect(page).to have_content("(inactive)")
    end
  end
end
