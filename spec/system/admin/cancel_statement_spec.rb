# frozen_string_literal: true

require "rails_helper"

RSpec.describe "canceling statements" do
  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility:) }
  let!(:order) { create(:complete_order, product: item, quantity: 3, account: create(:purchase_order_account, :with_account_owner, facility:)) }
  let(:order_details) { order.order_details }
  let!(:statement) { create(:statement, facility:) }
  let(:director) { create(:user, :facility_director, facility:) }

  before do
    order_details.each do |od|
      od.statement = statement
      od.save
    end

    login_as director
    visit facility_statements_path(facility)
  end

  context "when an order detail is NOT reconciled" do
    it "cancels a statement" do
      click_on "Cancel"
      expect(page).to have_content "#{I18n.t('Statement')} has been canceled"
      expect(page).to have_content "Canceled"
    end

    it "does not allow download or emailing of statement" do
      click_on "Cancel"
      expect(page).to_not have_content "Download"
      expect(page).to_not have_content "Resend"
      expect(page).to_not have_link "Cancel"
    end
  end

  context "when an order detail is reconciled" do
    before do
      order_details.first.to_reconciled!
      visit facility_statements_path(facility)
    end

    it "does not allow statement to be canceled" do
      expect(page).to have_content "Download"
      expect(page).to have_content "Resend"
      expect(page).to_not have_link "Cancel"
    end
  end
end
