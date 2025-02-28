# frozen_string_literal: true

require "rails_helper"

RSpec.describe "instrument reservations" do
  describe "shared schedule", :js do
    let(:admin) { create(:user, :administrator) }
    let!(:instrument) { create(:setup_instrument, :always_available) }
    let!(:instrument2) do
      create(
        :setup_instrument,
        :always_available,
        facility:,
        schedule: instrument.schedule
      )
    end
    let(:facility) { instrument.facility }
    let!(:reservation2) do
    end

    before do
      # Use actual current time so
      # loaded reservations are correct
      travel_back

      login_as admin
      create(
        :purchased_reservation,
        reserve_start_at: 1.hour.from_now,
        reserve_end_at: 2.hours.from_now,
        product: instrument
      )
    end

    it "show current instrument reservation with default color" do
      visit facility_instrument_schedule_path(facility, instrument)

      expect(page).to have_css(".fc-event")
      expect(page).not_to have_css(".fc-event.other-instrument")
    end

    it "shows other instrument reservations with different color", :js do
      create(
        :purchased_reservation,
        reserve_start_at: Time.zone.now,
        reserve_end_at: 1.hour.from_now,
        product: instrument2
      )

      visit facility_instrument_schedule_path(facility, instrument)

      save_and_open_screenshot

      expect(page).to have_css(".fc-event.other-instrument")
    end
  end
end
