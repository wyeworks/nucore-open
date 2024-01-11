# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Creating a journal" do
  let(:admin) { FactoryBot.create(:user, :administrator) }
  let(:user) { FactoryBot.create(:user) }
  let(:facility) { FactoryBot.create(:facility) }
  let(:account) { FactoryBot.create(Settings.testing.account_factory.to_sym, :with_account_owner, owner: user, facilities: [facility]) }
  let!(:account_api_record) { create(Settings.testing.api_account_factory.to_sym, account_number: account.account_number) } if Settings.testing.api_account_factory
  let!(:reviewed_order_detail) { place_and_complete_item_order(user, facility, account, true) }
  let!(:unreviewed_order_detail) { place_and_complete_item_order(user, facility, account) }
  let(:expiry_date) { 1.year.ago }
  let(:expired_payment_source) { FactoryBot.create(Settings.testing.account_factory.to_sym, :with_account_owner, owner: user, expires_at: expiry_date, facilities: [facility]) }
  let!(:problem_order_detail) { place_and_complete_item_order(user, facility, expired_payment_source, true) }

  before do
    unreviewed_order_detail.update(reviewed_at: nil)
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

  describe "creating a journal", :js do
    context "with no journal creation reminder" do
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

    context "with a past journal creation reminder" do
      before do
        JournalCreationReminder.create(starts_at: 2.weeks.ago, ends_at: 2.days.ago, message: "We are in the year-end closing window.")
        visit new_facility_journal_path(facility)
      end

      it "can select order details and create a journal" do
        expect(page).to have_content(OrderDetailPresenter.new(reviewed_order_detail).description_as_html)
        check "order_detail_ids_"
        click_button "Create"
        # Sometimes the first click doesn't work, so try again
        click_button "Create" unless page.has_content?("Pending Journal")
        expect(page).to have_content "Pending Journal"
      end

      context "with an order detail more than 90 days old" do
        before do
          reviewed_order_detail.fulfilled_at = 95.days.ago
          reviewed_order_detail.save
          visit new_facility_journal_path(facility)
        end

        it "has a 90 day pop up when 'Select All' is clicked" do
          click_on "Select All"
          click_button "Create"
          expect(page).to have_content "90-Day Justification"
          click_button "OK"
          # Sometimes the first click doesn't work, so try again
          click_button "OK" unless page.has_content?("The journal file has been created successfully")
          expect(page).to have_content "The journal file has been created successfully"
        end

        it "has a 90 day pop up when the check box is checked" do
          check "order_detail_ids_"
          click_button "Create"
          expect(page).to have_content "90-Day Justification"
          click_button "OK"
          # Sometimes the first click doesn't work, so try again
          click_button "OK" unless page.has_content?("The journal file has been created successfully")
          expect(page).to have_content "The journal file has been created successfully"
        end
      end
    end

    context "with a future journal creation reminder" do
      before do
        JournalCreationReminder.create(starts_at: 2.weeks.from_now, ends_at: 2.months.from_now, message: "We are in the year-end closing window.")
        visit new_facility_journal_path(facility)
      end

      it "can select order details and create a journal" do
        expect(page).to have_content(OrderDetailPresenter.new(reviewed_order_detail).description_as_html)
        check "order_detail_ids_"
        click_button "Create"
        # Sometimes the first click doesn't work, so try again
        click_button "Create" unless page.has_content?("Pending Journal")
        expect(page).to have_content "Pending Journal"
      end
    end

    context "with a current journal creation reminder" do
      before do
        JournalCreationReminder.create(starts_at: 2.days.ago, ends_at: 2.days.from_now, message: "We are in the year-end closing window.")
        visit new_facility_journal_path(facility)
      end

      it "can see a reminder message, then select order details and create a journal" do
        expect(page).to have_content(OrderDetailPresenter.new(reviewed_order_detail).description_as_html)
        check "order_detail_ids_"
        click_button "Create"
        expect(page).to have_content("We are in the year-end closing window.")
        click_button "Create Journal"
        # Sometimes the first click doesn't work, so try again
        click_button "Create Journal" unless page.has_content?("Pending Journal")
        expect(page).to have_content "Pending Journal"
      end

      context "with an order detail more than 90 days old" do
        before do
          reviewed_order_detail.fulfilled_at = 95.days.ago
          reviewed_order_detail.save
          visit new_facility_journal_path(facility)
        end

        it "has a 90 day and journal creation reminder pop up" do
          check "order_detail_ids_"
          click_button "Create"
          expect(page).to have_content "90-Day Justification"
          click_link "OK"
          # Sometimes the first click doesn't work, so try again
          click_link "OK" unless page.has_content?("We are in the year-end closing window.")
          expect(page).to have_content "We are in the year-end closing window."
        end

        it "has NO 90 day and journal creation reminder pop up when nothing is checked" do
          click_button "Create"
          expect(page).not_to have_content "90-Day Justification"
          expect(page).to have_content "We are in the year-end closing window."
        end
      end
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
