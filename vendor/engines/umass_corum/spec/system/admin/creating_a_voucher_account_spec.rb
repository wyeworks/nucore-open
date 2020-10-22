# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a Voucher Split Account" do
  let(:facility) { create(:setup_facility) }
  let(:admin) { create(:user, :administrator) }
  let!(:purchase_order) { create(:purchase_order_account, :with_account_owner, facility: facility) }
  let!(:credit_card) { create(:credit_card_account, :with_account_owner, facility: facility) }


  before do
    login_as(admin)
    visit new_facility_account_path(facility, owner_user_id: admin.id)

    click_link "Voucher Split Account"
  end

  describe "happy path" do
    it "can add the new account" do
      fill_in "Account Number", with: "123456"
      fill_in "Description", with: "Some description"

      select purchase_order.to_s, from: "Primary subaccount"
      select "50", from: "MIVP Percent"
      click_button "Create"

      expect(page).to have_content "Account was successfully created"
    end
  end

  describe "error path" do
    it "can add the new account" do
      click_button "Create"

      expect(page).to have_content "There were problems with the following fields"
    end
  end
end
