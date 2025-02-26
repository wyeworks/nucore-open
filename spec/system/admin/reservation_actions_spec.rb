# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reservation actions", :js do
  include_context "cross core orders"

  let(:facility2_instrument) { create(:setup_instrument, facility: facility2) }
  let(:cross_core_reservation_order) { create(:setup_order, cross_core_project:, product: facility2_instrument, account: accounts.last) }
  let!(:reservation) { create(:purchased_reservation, order_detail: cross_core_reservation_order.order_details.first) }

  before do
    allow_any_instance_of(InstrumentIssue).to receive(:send_notification).and_return(true)

    login_as facility_administrator
    visit facility_order_path(facility, originating_order_facility1)
  end

  describe "Report an Issue" do
    it "redirects to original order show" do
      find("h3", text: cross_core_reservation_order.facility.to_s, match: :first).click
      find("a", text: "Report an Issue").click
      fill_in "Message", with: "This is a test issue"
      click_button "Report Issue"

      expect(page).to have_content("Thank you. Your issue has been reported.")
      expect(page).to have_content("Order ##{originating_order_facility1.id}")
    end
  end

  describe "Cancel reservation" do
    it "redirects to original order show" do
      find("h3", text: cross_core_reservation_order.facility.to_s, match: :first).click
      accept_confirm do
        click_link("Cancel")
      end
      expect(page).to have_content("The reservation has been canceled successfully")
    end
  end

  describe "Move up" do
    it "redirects to original order show" do
      find("h3", text: cross_core_reservation_order.facility.to_s, match: :first).click
      find("a", text: "Move Up").click

      wait_for_ajax

      expected_flash_message = "The reservation was moved successfully."

      click_button "Move"
      # Sometimes the first click doesn't work, so try again
      click_button "Move" unless page.has_content?(expected_flash_message)

      expect(page).to have_content(expected_flash_message)
      expect(page).to have_content("Order ##{originating_order_facility1.id}")
    end
  end
end
