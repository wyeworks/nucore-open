# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing a SpeedType" do
  let(:facility) { create(:setup_facility) }
  let(:facility_admin) { create(:user, :facility_administrator, facility: facility) }
  let(:global_admin) { create(:user, :administrator) }

  describe "creating a speed type" do
    before do
      login_as(facility_admin)
      visit new_facility_account_path(facility, owner_user_id: facility_admin.id)

      click_link "SpeedType"
    end

    describe "with an active speed type from the api" do
      let(:response) do
        {
          "speed_type" => "123456",
          "active" => true,
          "date_added" => "2018-01-01T08:00",
        }
      end

      before do
        allow(UmassCorum::ApiSpeedType).to receive(:fetch).with("123456").and_return(response)
      end

      it "can add the speed type" do
        fill_in "Account Number", with: "123456"
        fill_in "Description", with: "Some description"

        click_button "Create"

        expect(page).to have_content "Account was successfully created"
      end

    end

    describe "with an inactive speed type from the api" do
      let(:response) do
        {
          "speed_type" => "123456",
          "active" => false,
          "date_added" => "2018-01-01T08:00",
          "date_removed" => "2019-01-01T08:00",
          "error_desc" => "Speed type is not active"
        }
      end

      before do
        allow(UmassCorum::ApiSpeedType).to receive(:fetch).with("123456").and_return(response)
      end

      it "can add the speed type" do
        fill_in "Account Number", with: "123456"
        fill_in "Description", with: "Some description"

        click_button "Create"

        expect(page).to have_content "Speed type is not active"
      end
    end

    it "fails without hitting the api if it is not the right format" do
      fill_in "Account Number", with: "12345"
      click_button "Create"
      expect(page).to have_content "must be a six digit number"
    end
  end

  describe "editing a speed type" do
    let(:speed_type_account) { create(:speed_type_account, :with_account_owner, :with_api_speed_type) }

    it "can override date_added when a global admin is editing the speed type" do
      login_as(global_admin)
      visit edit_facility_account_path(facility, speed_type_account)

      override_date_string = "03/25/2021"
      fill_in "Date added", with: override_date_string

      click_button "Save"

      expect(page).to have_content override_date_string
    end

    it "cannot override date_added when a facility admin is editing the speed type" do
      login_as(facility_admin)
      visit edit_facility_account_path(facility, speed_type_account)

      expect(page).not_to have_content "Date added"
    end
  end
end
