# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductNotificationsController, feature_setting: { training_requests: true, reload_routes: true } do
  let(:facility) { create(:setup_facility) }
  let!(:instrument) { create(:instrument, facility: facility) }

  describe "as a facility director" do
    before { login_as create(:user, :facility_director, facility: facility) }

    it "can update the fields" do
      visit facility_instruments_path(facility)
      click_link instrument.name
      click_link "Notifications"
      click_link "Edit"

      fill_in "Order Notification Recipient", with: "user1@example.com"
      fill_in "Cancellation Notification Recipients", with: "user2@example.com, user3@example.com"
      fill_in "Training Request Recipients", with: "user4@example.com, user5@example.com"
      click_button "Save"

      expect(page).to have_content("Order Notification Recipient\nuser1@example.com")
      expect(page).to have_content("Cancellation Notification Recipients\nuser2@example.com, user3@example.com")
      expect(page).to have_content("Training Request Recipients\nuser4@example.com, user5@example.com")
    end
  end

  describe "as facility senior staff" do
    before { login_as create(:user, :senior_staff, facility: facility) }

    it "does not see the edit button" do
      visit facility_instruments_path(facility)
      click_link instrument.name
      click_link "Notifications"
      expect(page).not_to have_link("Edit")
    end

    it "cannot access the edit view" do
      visit edit_facility_product_notifications_path(facility, instrument)
      expect(page).to have_content("Permission Denied")
    end
  end
end
