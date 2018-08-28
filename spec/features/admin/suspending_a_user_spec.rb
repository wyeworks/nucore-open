# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User suspension", feature_setting: { create_users: true } do
  let(:facility) { create(:facility) }
  let(:user) { create(:user, email: "todelete@example.com", first_name: "Del", last_name: "User") }

  describe "as a global admin" do
    let(:admin) { create(:user, :administrator) }

    it "can suspend and reactivate a user" do
      login_as admin
      visit facility_user_path(facility, user)

      expect(page).to have_content("todelete@example.com")
      click_link "Suspend"
      expect(page).to have_content("Del User (SUSPENDED)")

      click_link "Activate"
      expect(page).not_to have_content("(SUSPENDED)")
    end
  end

  describe "as a facility admin" do
    let(:admin) { create(:user, :facility_administrator, facility: facility) }

    it "cannot suspend user" do
      login_as admin
      visit facility_user_path(facility, user)

      expect(page).to have_content("todelete@example.com")
      expect(page).not_to have_link("Suspend")
      expect(page).not_to have_link("Activate")
    end
  end
end
