require "rails_helper"

RSpec.describe "Managing recharge accounts (FacilityFacilityAccountsController)" do

  let(:facility) { FactoryBot.create(:facility) }
  let!(:director) { FactoryBot.create(:user, :facility_director, facility: facility) }
  let(:default_revenue_account) { Settings.accounts.revenue_account_default }
  # Use this so schools can override their own formats
  let(:dummy_account) { build(:facility_account) }

  # This will run only in schools who have not overridden their validator with a
  # custom one. If it's custom, then the school should write their own feature spec.
  it "can create a recharge account", if: ValidatorFactory.validator_class == ::ValidatorDefault do
    login_as director
    visit manage_facility_path(facility)

    click_link "Recharge Chart Strings"
    click_link "Add Recharge Chart String"

    fill_in "Account Number", with: dummy_account.account_number

    click_button "Create"

    expect(page).to have_content("Recharge Chart String was successfully created")
    expect(page).to have_link(dummy_account.to_s)
  end

  describe "editing an existing" do
    let!(:facility_account) { FactoryBot.create(:facility_account, facility: facility) }

    it "cannot edit most fields, but can mark it as inactive" do
      login_as director
      visit manage_facility_path(facility)

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
