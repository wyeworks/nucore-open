# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a journal" do

  let(:admin) { FactoryBot.create(:user, :administrator) }
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:facility) }
  let(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, facility: facility) }
  let!(:reviewed_order_detail) { place_and_complete_item_order(user, facility, account, true) }
  let!(:unreviewed_order_detail) { place_and_complete_item_order(user, facility, account) }
  let(:expiry_date) { Time.zone.now - 1.year }
  let(:expired_payment_source) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user, expires_at: expiry_date, facility: facility) }
  let!(:problem_order_detail) { place_and_complete_item_order(user, facility, expired_payment_source, true) }

  before do
    unreviewed_order_detail.update_attributes(reviewed_at: nil)
    [reviewed_order_detail, problem_order_detail].each do |od|
      od.update_attribute(:reviewed_at, 1.day.ago)
    end

    login_as admin
  end

  describe "new journal page" do
    before do
      visit new_facility_journal_path(facility)
    end

    it "has journalable order details" do
      expect(page).to have_content("Select the orders that you wish to journal.")
      expect(page).to have_content(OrderDetailPresenter.new(reviewed_order_detail).description_as_html)
    end

    it "does not have unreviewed order details" do
      expect(page).not_to have_content(OrderDetailPresenter.new(unreviewed_order_detail).description_as_html)
    end

    it "has invalid payment order details" do
      expect(page).to have_content("These payment sources were not valid at the time of fulfillment.")
      expect(page).to have_content(OrderDetailPresenter.new(problem_order_detail).description_as_html)
      expect(page).to have_content(problem_order_detail.account.expires_at.strftime("%m/%d/%Y"))
    end
  end

  describe "creating a journal" do
    before do
      visit new_facility_journal_path(facility)
    end

    it "can select order details and create a journal" do
      expect(page).to have_content(OrderDetailPresenter.new(reviewed_order_detail).description_as_html)
      check "order_detail_ids_"
      click_button "Create"
      expect(page).to have_content "Pending Journal"
    end
  end

  describe "exporting problem orders" do
    before do
      visit new_facility_journal_path(facility)
    end

    it "can export problem orders to a csv" do
      expect(page).to have_content("These payment sources were not valid at the time of fulfillment.")
      click_link "Export Errors as CSV"
      expect(page).to have_content("A report is being prepared and will be emailed")
    end
  end

end
