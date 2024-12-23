# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing User Details", :aggregate_failures, feature_setting: { create_users: true, user_based_price_groups: true, reload_routes: true } do
  let(:facility) { FactoryBot.create(:facility) }
  let(:admin) { FactoryBot.create(:user, :netid, :administrator) }

  before do
    login_as admin
  end

  describe "create", js: true do
    it "creates an external user" do
      visit new_external_facility_users_path(facility)

      fill_in "First name", with: "Moana"
      fill_in "Last name", with: "Waialiki"
      fill_in "Email", with: "moana@maui.island"

      check("user[no_netid]") if has_css?("#user_no_netid")

      click_on "Create"

      expect(page).to have_content("You just created a new user, Moana Waialiki (moana@maui.island)")

      expect(page).to have_content("if this user is entitled to internal rates.")
    end
  end

  describe "edit" do
    describe "as a facility admin" do
      let(:user) { FactoryBot.create(:user, :netid, username: "user123") }

      before do
        visit facility_user_path(facility, user)
      end

      it "allows admin to edit internal/external pricing" do
        expect(page).to have_content("Internal Pricing")

        click_link "Edit"

        select "No", from: "user_internal"

        click_button "Update"

        expect(page).to have_content("Internal Pricing\nNo")

        click_link "Edit"

        select "Yes", from: "user_internal"

        click_button "Update"

        expect(page).to have_content("Internal Pricing\nYes")
      end
    end

    describe "editing an external (email-based) user" do
      let(:admin) { FactoryBot.create(:user, :netid, :administrator) }
      let(:user) { FactoryBot.create(:user, :external, last_name: "Skywalker") }

      describe "#edit" do
        before do
          login_as admin
          visit facility_user_path(facility, user)
        end

        it "allows editing" do
          expect(page).to have_content("Skywalker")
          expect(page).not_to have_content("Vader")

          click_link "Edit"

          fill_in "Last name", with: "Vader"

          click_button "Update"

          expect(page).not_to have_content("Edit User")
          expect(page).to have_content("Vader")
          expect(page).not_to have_content("Skywalker")
        end
      end
    end

    describe "as an account admin" do
      let!(:account_admin) { FactoryBot.create(:user, :account_manager) }
      let!(:user) { FactoryBot.create(:user) }

      before do
        login_as account_admin
        visit facility_user_path(Facility.cross_facility, user)
      end

      it "does not allow account admin to edit" do
        expect(page).to have_content("Internal Pricing")
        expect(page).not_to have_link "Edit"
      end

      it_behaves_like "raises specified error", -> { visit edit_facility_user_path(Facility.cross_facility, user) }, CanCan::AccessDenied
    end
  end
end
