# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing User custom fields" do

  let(:facility) { FactoryBot.create(:facility) }
  let(:admin) { FactoryBot.create(:user, :administrator) }

  describe "with an internal user" do
    let(:user) { FactoryBot.create(:user) }

    describe "new" do
      before do
        login_as admin
        visit new_facility_user_path(facility)
      end

      it "can specify Phone Number when creating" do
        expect(page).to have_content("Phone number")

        fill_in "First name", with: "Danny"
        fill_in "Last name", with: "Devito"
        fill_in "Email", with: "Danny@devi.to"
        fill_in "NetID", with: "ddevito"
        fill_in "Phone number", with: "123-123-1234"

        click_button "Create"

        expect(current_path).to eq(facility_users_path(facility))

        click_link("Danny Devito")

        expect(page).to have_content("123-123-1234")
      end
    end

    describe "edit" do
      before do
        login_as admin
        visit facility_user_path(facility, user)
      end

      it "allows admin to edit Phone number" do
        expect(page).to have_content("Phone number")

        click_link "Edit"

        fill_in "Phone number", with: "123-123-1234"

        click_button "Update"

        expect(page).to have_content("123-123-1234")

        click_link "Edit"

        fill_in "Phone number", with: "456-456-4564"

        click_button "Update"

        expect(page).to have_content("456-456-4564")
      end
    end
  end

  describe "with an external user" do
    describe "new" do
      before do
        login_as admin
        visit new_external_facility_users_path(facility)
      end

      it "can specify Phone Number when creating" do
        expect(page).to have_content("Phone number")

        fill_in "First name", with: "Danny"
        fill_in "Last name", with: "Devito"
        fill_in "Email", with: "Danny@devi.to"
        fill_in "Phone number", with: "123-123-1234"
        check "This user does not have a NetID"

        click_button "Create"

        expect(current_path).to eq(facility_users_path(facility))

        click_link("Danny Devito")

        expect(page).to have_content("123-123-1234")
      end
    end

    describe "edit" do
      let(:user) { FactoryBot.create(:user, :external) }

      before do
        login_as admin
        visit facility_user_path(facility, user)
      end

      it "allows admin to edit Phone number" do
        expect(page).to have_content("Phone number")

        click_link "Edit"

        fill_in "Phone number", with: "123-123-1234"

        click_button "Update"

        expect(page).to have_content("123-123-1234")

        click_link "Edit"

        fill_in "Phone number", with: "456-456-4564"

        click_button "Update"

        expect(page).to have_content("456-456-4564")
      end
    end
  end

end
