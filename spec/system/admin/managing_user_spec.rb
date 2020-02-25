# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing User Details", :aggregate_failures, feature_setting: { create_users: true, user_based_price_groups: true, reload_routes: true } do

  let(:facility) { FactoryBot.create(:facility) }

  describe "edit" do
    describe "as a facility admin" do
      let(:admin) { FactoryBot.create(:user, :administrator) }
      let(:user) { FactoryBot.create(:user, username: "user123") }

      before do
        login_as admin
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

      it "cannot access the page" do
        visit edit_facility_user_path(Facility.cross_facility, user)
        expect(page).to have_content("Permission Denied")
      end

    end

  end
end
