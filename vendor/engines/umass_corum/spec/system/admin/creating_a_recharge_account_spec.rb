require "rails_helper"

RSpec.describe "Creating a recharge account" do
  let(:facility) { FactoryBot.create(:facility) }
  let(:facility_admin) { create(:user, :facility_administrator, facility: facility) }

  before do
    login_as facility_admin
    visit facility_facility_accounts_path(facility)
    click_link "Add Recharge Chart String"
  end

  describe "happy path" do
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
      fill_in "Revenue Account", with: "612345"
      click_button "Create"
      expect(page).to have_content("was successfully created")
    end
  end

  it "gets an error if it's not the right format" do
    fill_in "Account Number", with: "15690"
    click_button "Create"
    expect(page).to have_content("must be a six digit number")
  end

  it "gets an error if the account does not start with a 6" do
    fill_in "Account Number", with: "123456"
    fill_in "Revenue Account", with: "512345"
    click_button "Create"
    expect(page).to have_content("must be a six digit number starting with 6")
  end
end
