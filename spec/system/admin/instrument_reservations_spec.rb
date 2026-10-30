# frozen_string_literal: true

require "rails_helper"

RSpec.describe "instrument reservations" do
  describe "shared schedule", :js, :skip_time_travel do
    let(:admin) { create(:user, :administrator) }
    let!(:instrument) { create(:setup_instrument, :always_available) }
    let!(:instrument2) do
      create(
        :setup_instrument,
        :always_available,
        facility:,
        schedule: instrument.schedule,
      )
    end
    let(:facility) { instrument.facility }
    let!(:reservation2) do
    end

    before do
      login_as admin
      create(
        :purchased_reservation,
        reserve_start_at: 2.hours.from_now,
        reserve_end_at: 3.hours.from_now,
        product: instrument,
      )
    end

    it "show current instrument reservation with default color" do
      visit facility_instrument_schedule_path(facility, instrument)

      expect(page).to have_css(".fc-event")
      expect(page).not_to have_css(".fc-event.other-instrument")
    end

    it "shows other instrument reservations with different color" do
      create(
        :purchased_reservation,
        reserve_start_at: Time.zone.now,
        reserve_end_at: 1.hour.from_now,
        product: instrument2,
      )

      visit facility_instrument_schedule_path(facility, instrument)

      expect(page).to have_css(".fc-event.other-instrument")
    end
  end

  describe "show canceled", :js, :skip_time_travel do
    let(:admin) { create(:user, :administrator) }
    let!(:instrument) { create(:setup_instrument, :always_available) }
    let(:facility) { instrument.facility }

    before do
      login_as admin
      create(
        :purchased_reservation,
        reserve_start_at: 2.hours.from_now,
        reserve_end_at: 3.hours.from_now,
        product: instrument,
      )
      create(
        :purchased_reservation,
        :canceled,
        reserve_start_at: 4.hours.from_now,
        reserve_end_at: 5.hours.from_now,
        product: instrument,
      )

      visit facility_instrument_schedule_path(facility, instrument)
    end

    it "hides canceled reservations until the checkbox is checked" do
      expect(page).to have_css(".fc-event")
      expect(page).not_to have_css(".fc-event.canceled")

      check "show_canceled"

      expect(page).to have_css(".fc-event.canceled")

      uncheck "show_canceled"

      expect(page).not_to have_css(".fc-event.canceled")
    end

    it "preserves the checkbox state across a page reload" do
      check "show_canceled"

      expect(page).to have_css(".fc-event.canceled")

      visit current_url

      expect(page).to have_checked_field("show_canceled")
      expect(page).to have_css(".fc-event.canceled")
    end

    it "drops the parameter again when unchecked" do
      check "show_canceled"
      uncheck "show_canceled"

      visit current_url

      expect(page).to have_unchecked_field("show_canceled")
      expect(page).not_to have_css(".fc-event.canceled")
    end
  end
end
