# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Launching Kiosk View", feature_setting: { kiosk_view: true } do
  let(:facility) { create(:setup_facility, kiosk_enabled: true) }
  let(:director) { create(:user, :facility_director, facility: facility) }

  before { login_as director }

  context "with active reservations" do
    let(:instrument) { create(:setup_instrument, :timer, facility: facility) }

    before { create(:purchased_reservation, :running, product: instrument) }

    it "can launch the Kiosk View" do
      visit timeline_facility_reservations_path(facility)
      click_link "Launch Kiosk View"
      expect(page.current_path).to eq facility_kiosk_reservations_path(facility)
      # user should be logged out
      expect(page).to have_content("Login")
    end

    it "does not raise an error when refreshing" do
      visit facility_kiosk_reservations_path(facility, refresh: true)
      expect(page).to have_content(instrument.name)
    end
  end

  context "with no active reservations" do
    it "cannot launch the Kiosk View" do
      visit timeline_facility_reservations_path(facility)
      expect(page).not_to have_content("Launch Kiosk View")
    end

    it "does not raise an error when refreshing" do
      visit facility_kiosk_reservations_path(facility, refresh: true)
      expect(page).to have_content("No currently actionable reservations found")
    end
  end

  context "with Kiosk view disabled" do
    let(:facility) { create(:setup_facility, kiosk_enabled: false ) }

    it "cannot launch the Kiosk View" do
      visit timeline_facility_reservations_path(facility)
      expect(page).not_to have_content("Launch Kiosk View")
    end
  end

  context "with the feature flag turned off", feature_setting: { kiosk_view: false } do
    it "cannot launch the Kiosk View" do
      visit timeline_facility_reservations_path(facility)
      expect(page).not_to have_content("Launch Kiosk View")
    end
  end
end
