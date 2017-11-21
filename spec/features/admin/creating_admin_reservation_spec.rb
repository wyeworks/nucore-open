require "rails_helper"

RSpec.describe "Creating an admin reservation" do
  let(:facility) { FactoryGirl.create(:setup_facility) }
  let(:director) { FactoryGirl.create(:user, :facility_director, facility: facility) }
  let(:instrument) { FactoryGirl.create(:setup_instrument, facility: facility) }

  before { login_as director }
  let(:fiscal_year) { SettingsHelper.fiscal_year_beginning.year }

  it "can place an admin reservation" do
    visit new_facility_instrument_reservation_path(facility, instrument)

    fill_in "Reserve start date", with: "10/17/#{fiscal_year}"
    fill_in "Duration mins", with: "30"
    click_button "Create"

    expect(page).to have_content "10/17/#{fiscal_year} 9:30 AM - 10:00 AM"
  end

end
