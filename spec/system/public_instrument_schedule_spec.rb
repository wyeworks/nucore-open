# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public instrument schedule", :js, :skip_time_travel do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, facility:, show_details: true) }
  let(:customer) { create(:user) }
  let!(:reservation) do
    create(:purchased_reservation, product: instrument, user: customer, reserve_start_at: Time.current.change(hour: 12, min: 30))
  end

  it "does not show the customer's name to an anonymous user" do
    visit facility_instrument_public_schedule_path(facility, instrument)

    expect(page).to have_css(".fc-title", text: "Reservation")
    expect(page).not_to have_content(customer.full_name)
  end

  it "shows the customer's name to a signed in user",
     feature_setting: { "reservations.show_details_to_customers": true } do
    login_as create(:user)
    visit facility_instrument_public_schedule_path(facility, instrument)

    expect(page).to have_css(".fc-title", text: customer.full_name)
  end

  context "when customers cannot see reservation details", feature_setting: { "reservations.show_details_to_customers": false } do
    it "does not show the customer's name to a signed in user" do
      login_as create(:user)
      visit facility_instrument_public_schedule_path(facility, instrument)

      expect(page).to have_css(".fc-title", text: "Reservation")
      expect(page).not_to have_content(customer.full_name)
    end

    it "shows the customer's own name to the customer" do
      login_as customer
      visit facility_instrument_public_schedule_path(facility, instrument)

      expect(page).to have_css(".fc-title", text: customer.full_name)
    end

    it "shows the customer's name to facility staff" do
      login_as create(:user, :staff, facility:)
      visit facility_instrument_public_schedule_path(facility, instrument)

      expect(page).to have_css(".fc-title", text: customer.full_name)
    end
  end
end
