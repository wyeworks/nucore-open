# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Importing Approved Users", :js do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:instrument) { create(:instrument_requiring_approval, facility: facility) }
  let!(:user_1) { create(:user, username: "ddavidson") }
  let!(:user_2) { create(:user, username: "jjacobson") }

  before { login_as director }

  context "when all usernames are skipped" do
    before(:each) do
      create(:product_user, product: instrument, user: user_1)
      create(:product_user, product: instrument, user: user_2)
    end

    it "displays the correct message" do
      visit facility_instrument_users_path(facility, instrument)
      page.attach_file("#{Rails.root}/spec/files/product_user_imports/existing_users.csv", visible: false)

      expect(page.current_path).to eq facility_instrument_users_path(facility, instrument)
      expect(page).to have_content("No new approved users were added.\nThe following user(s) already had access:\n#{user_1.username}\n#{user_2.username}\n")
      expect(page).not_to have_content("imported successfully")
    end
  end

  context "when some usernames are skipped and some are imported" do
    before(:each) do
      create(:product_user, product: instrument, user: user_1)
    end

    it "displays the correct message" do
      visit facility_instrument_users_path(facility, instrument)
      page.attach_file("#{Rails.root}/spec/files/product_user_imports/existing_users.csv", visible: false)

      expect(page.current_path).to eq facility_instrument_users_path(facility, instrument)
      expect(page).to have_content("The following user(s) already had access:\n#{user_1.username}\n")
      expect(page).to have_content("1 new approved user imported successfully")
    end
  end

  context "when some usernames are found and some are not found" do
    before(:each) do
      create(:product_user, product: instrument, user: user_1)
    end

    it "displays the correct message" do
      visit facility_instrument_users_path(facility, instrument)
      page.attach_file("#{Rails.root}/spec/files/product_user_imports/user_not_found.csv", visible: false)

      expect(page.current_path).to eq facility_instrument_users_path(facility, instrument)
      expect(page).to have_content("1 error(s) occurred while importing:\nwhoami: User not found")
      expect(page).not_to have_content("The following user(s) already had access")
      expect(page).not_to have_content("imported successfully")
    end
  end
end
