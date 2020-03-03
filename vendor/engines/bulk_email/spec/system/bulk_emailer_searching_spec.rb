# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Bulk email search", feature_setting: { training_requests: true, reload_routes: true } do
  let!(:training_request) { create(:training_request) }
  let(:facility) { training_request.product.facility }
  let(:instrument) { training_request.product }
  let(:user) { training_request.user }

  describe "single facility context" do
    let(:director) { create(:user, :facility_director, facility: facility) }
    before { login_as director }

    it "can trigger an email" do
      visit facility_bulk_email_path(facility)

      check "Authorized Users"
      click_button "Search"

      expect(page).to have_content("No users found")

      check "Users on Training Request List"
      click_button "Search"
      expect(page).to have_content(user.email)

      find("#format", visible: false).set "html" # Handled by JS normally
      click_button "Compose Mail"

      expect(page).to have_field("Recipients", with: user.email, disabled: true, type: "textarea")

      fill_in "Subject line", with: "Hello, friends"
      fill_in "Message", with: "Howdy!"
      click_button "Send Mail"
      expect(page).to have_content("queued successfully")

      click_link "History"
      click_link "View details"
      expect(page).to have_content("Hello, friends")
    end
  end

  describe "cross-facility context" do
    let(:admin) { create(:user, :administrator) }
    let!(:facility2) { create(:facility) }

    before { login_as admin }

    it "can trigger an email" do
      visit root_path
      click_link "Users", match: :first
      click_link "Bulk Email"

      check "Users on Training Request List"
      click_button "Search"
      expect(page).to have_content(user.email)

      select facility2.name, from: "facilities" # The label's `for` does not match the `select`'s `id`
      click_button "Search"
      expect(page).to have_content("No users found")

      select facility.name, from: "facilities"
      click_button "Search"
      expect(page).to have_content(user.email)

      find("#format", visible: false).set "html" # Handled by JS normally
      click_button "Compose Mail"

      expect(page).to have_field("Recipients", with: user.email, disabled: true, type: "textarea")

      fill_in "Subject line", with: "Hello, friends"
      fill_in "Message", with: "Howdy!"
      click_button "Send Mail"
      expect(page).to have_content("queued successfully")

      click_link "History"
      click_link "View details"
      expect(page).to have_content("Hello, friends")
      expect(page).to have_content([facility, facility2].join(", "))
    end
  end
end
