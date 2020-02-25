# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User's Card Number" do
  let(:facility) { FactoryBot.create(:facility) }
  let(:card_user) { FactoryBot.create(:user) }
  let(:staff_user) { FactoryBot.create(:user, :staff, facility: facility) }

  describe "update" do
    before do
      login_as staff_user
      visit facility_user_path(facility, card_user)
      click_link "Secure Room Access"
      fill_in "Card Number", with: "123456"
      click_button "Update"
    end

    it "successfully updates the card number" do
      expect(card_user.reload.card_number).to eq "123456"
    end
  end
end
