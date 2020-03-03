# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility Statement Admin" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:accounts) { create_list(:account, 2, :with_account_owner, type: Account.config.statement_account_types.first) }
  let(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account: account) }
  end

  let(:order_details) { orders.map(&:order_details).flatten }

  before do
    order_details.each do |detail|
      detail.update(reviewed_at: 1.day.ago)
    end
  end

  describe "filtering on Create Statement" do
    it "can do a basic filter" do
      login_as director
      visit new_facility_statement_path(facility)
      select accounts.first.account_list_item, from: "Payment Sources"
      click_button "Filter"

      expect(page).to have_link(order_details.first.id.to_s, href: manage_facility_order_order_detail_path(facility, orders.first, order_details.first))
      expect(page).not_to have_link(order_details.second.id.to_s, href: manage_facility_order_order_detail_path(facility, orders.second, order_details.second))
    end
  end

  describe "searching statements" do
    let!(:statement1) { create(:statement, created_at: 3.days.ago, order_details: [order_details.first], account: order_details.first.account, facility: facility) }
    let!(:statement2) { create(:statement, created_at: 6.days.ago, order_details: [order_details.second], account: order_details.second.account, facility: facility) }

    before do
      login_as director
      visit facility_statements_path(facility)
    end

    it "can filter by the account" do
      expect(page).to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)

      select statement1.account.account_list_item, from: "Payment Sources"
      click_button "Filter"

      expect(page).to have_content(statement1.invoice_number)
      expect(page).not_to have_content(statement2.invoice_number)

      unselect statement1.account.account_list_item, from: "Payment Sources"
      select statement2.account.account_list_item, from: "Payment Sources"
      click_button "Filter"

      expect(page).not_to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)
    end

    it "can filter by the owner/business admin" do
      expect(page).to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)

      select statement1.account.owner_user.full_name, from: "Sent To"
      click_button "Filter"

      expect(page).to have_content(statement1.invoice_number)
      expect(page).not_to have_content(statement2.invoice_number)

      unselect statement1.account.owner_user.full_name, from: "Sent To"
      select statement2.account.owner_user.full_name, from: "Sent To"
      click_button "Filter"

      expect(page).not_to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)
    end

    it "can filter by dates" do
      fill_in "Start Date", with: I18n.l(4.days.ago.to_date, format: :usa)
      click_button "Filter"

      expect(page).to have_content(statement1.invoice_number)
      expect(page).not_to have_content(statement2.invoice_number)

      fill_in "Start Date", with: ""
      fill_in "End Date", with: I18n.l(4.days.ago.to_date, format: :usa)

      click_button "Filter"
      expect(page).not_to have_content(statement1.invoice_number)
      expect(page).to have_content(statement2.invoice_number)
    end

    it "sends a csv in an email" do
      expect { click_link "Export as CSV" }.to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
