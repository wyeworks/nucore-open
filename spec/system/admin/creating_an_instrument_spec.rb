# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating an instrument", :js do
  let(:facility) { create(:setup_facility) }

  describe "Daily Booking instrument" do
    context "as disallowed user" do
      let(:user) { create(:user, :facility_director, facility:) }

      it "cannot select daily booking pricing mode" do
        visit new_facility_instrument_path(facility)

        expect(page).to_not have_element(Instrument::Pricing::SCHEDULE_DAILY)
      end
    end

    context "as administrator" do
      let(:user) { create(:user, :administrator) }
      let(:instrument) { Instrument.last }

      before do
        login_as user
      end

      it "is accessible" do
        visit new_facility_instrument_path(facility)
        expect(page).to be_axe_clean.excluding(".cke_inner .cke_reset")
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
        expect(page).not_to have_field("Start Time Disabled")

        expect(page).to have_content(Instrument::Pricing::SCHEDULE_DAILY)

        choose Instrument::Pricing::SCHEDULE_DAILY

        expect(page).not_to have_field("Interval Minutes")
        expect(page).not_to have_field("Minimum (minutes)")
        expect(page).not_to have_field("Maximum (minutes)")
        expect(page).to have_field("Maximum (days)")
        expect(page).to have_field("Minimum (days)")
        expect(page).to have_field("Start Time Disabled")

        fill_in "Minimum (days)", with: "5"
        fill_in "Maximum (days)", with: "10"

        click_button "Create"

        expect(page).to have_content("Instrument was successfully created")
        expect(current_path).to eq(manage_facility_instrument_path(facility, Instrument.last))
        expect(page).to have_content("Daily Booking Instrument")
        expect(page).to have_content("Schedule Rule (Daily Booking only)")
        expect(page).to have_content("Min reserve days")
        expect(page).to have_content("Max reserve days")
        expect(page).to have_content("Start Time Disabled")
        expect(page).not_to have_content("Interval minutes")
        expect(page).not_to have_content("Min reserve minutes")
        expect(page).not_to have_content("Max reserve minutes")

        expect(instrument.min_reserve_days).to eq(5)
        expect(instrument.max_reserve_days).to eq(10)
        expect(instrument.start_time_disabled).to be false
      end

      it "can create an instrument with fixed time" do
        visit facility_products_path(facility)
        click_link "Instruments (0)", exact: true
        click_link "Add Instrument"

        fill_in "Name", with: "Daily Booking Instrument", match: :first
        fill_in "URL Name", with: "daily-booking-instrument"

        choose Instrument::Pricing::SCHEDULE_DAILY

        check("Start Time Disabled")

        click_button "Create"

        expect(page).to have_content("Instrument was successfully created")

        expect(instrument.start_time_disabled).to be true
      end
    end
  end
end
