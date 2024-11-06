# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating an instrument", :js do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility:) }

  before do
    login_as director
  end

  describe "Daily Booking instrument" do
    it "is accessible" do
      visit new_facility_instrument_path(facility)
      expect(page).to be_axe_clean
    end

    it "can create and see a daily booking instrument" do
      visit facility_products_path(facility)
      click_link "Instruments (0)", exact: true
      click_link "Add Instrument"

      fill_in "Name", with: "Daily Booking Instrument", match: :first
      fill_in "URL Name", with: "daily-booking-instrument"

      expect(page).to have_field("Interval (minutes)")
      expect(page).to have_field("Minimum (minutes)")
      expect(page).to have_field("Maximum (minutes)")
      expect(page).not_to have_field("Minimum (days)")
      expect(page).not_to have_field("Maximum (days)")

      choose "Schedule Rule (Daily Booking only)"

      expect(page).not_to have_field("Interval Minutes")
      expect(page).not_to have_field("Minimum (minutes)")
      expect(page).not_to have_field("Maximum (minutes)")
      expect(page).to have_field("Maximum (days)")
      expect(page).to have_field("Minimum (days)")

      fill_in "Minimum (days)", with: "5"
      fill_in "Maximum (days)", with: "10"

      click_button "Create"

      expect(current_path).to eq(manage_facility_instrument_path(facility, Instrument.last))
      expect(page).to have_content("Daily Booking Instrument")
      expect(page).to have_content("Schedule Rule (Daily Booking only)")
      expect(page).to have_content("Min reserve days")
      expect(page).to have_content("Max reserve days")
      expect(page).not_to have_content("Interval minutes")
      expect(page).not_to have_content("Min reserve minutes")
      expect(page).not_to have_content("Max reserve minutes")
    end
  end
end