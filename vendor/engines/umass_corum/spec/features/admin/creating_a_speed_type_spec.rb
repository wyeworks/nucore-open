# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a SpeedType" do
  let(:facility) { create(:setup_facility) }
  let(:facility_admin) { create(:user, :facility_administrator, facility: facility) }

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
