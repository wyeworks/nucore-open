# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Review period - Sending notifications and marking as reviewed", billing_review_period: 7.days do

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:accounts) { create_list(:setup_account, 2) }
  let(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account: account) }
  end
  let!(:order_details) { orders.flat_map(&:order_details) }

  before do
    order_details.each { |od| od.update(note: "OD ##{od.order_number}") }
    order_details.second.update(actual_cost: 0)
  end

  it "can do a basic search" do
    login_as director
    visit facility_notifications_path(facility)

    # Does not have default values for start/end
    expect(find_field("Start Date").value).to be_blank
    expect(find_field("End Date").value).to be_blank

    # Has both orders
    expect(page).to have_content("OD ##{order_details.first.order_number}")
    expect(page).to have_content("OD ##{order_details.second.order_number}")

    select accounts.first.account_list_item, from: "Payment Sources"
    click_button "Filter"

    # Has only the one from the selected account
    expect(page).to have_content("OD ##{order_details.first.order_number}")
    expect(page).not_to have_content("OD ##{order_details.second.order_number}")
  end

  context "when 'Send $0 Notifications?' checkbox is unchecked" do
    it "only sends notifications for orders > $0" do
      login_as director
      visit facility_notifications_path(facility)

      find("input[value='#{order_details.first.id}']").click
      find("input[value='#{order_details.second.id}']").click

      click_button "Send Notifications"

      expect(ActionMailer::Base.deliveries.count).to eq 1

      within(".notice") do
        expect(page).to have_content(accounts.first.account_list_item)
        # Only one notification is sent, the second order detail is $0
        expect(page).not_to have_content(accounts.second.account_list_item)
      end
      expect(page).to have_content("No notifications are currently pending")

      click_link "Orders In Review"

      # Both orders are now in review
      expect(page).to have_content("OD ##{order_details.first.order_number}")
      expect(page).to have_content("OD ##{order_details.second.order_number}")
    end
  end

  context "when 'Send $0 Notifications?' checkbox is checked" do
    it "sends notifications for all orders" do
      login_as director
      visit facility_notifications_path(facility)

      find("input[value='#{order_details.first.id}']").click
      find("input[value='#{order_details.second.id}']").click

      check "Send $0 Notifications?"
      click_button "Send Notifications"

      expect(ActionMailer::Base.deliveries.count).to eq 2

      within(".notice") do
        expect(page).to have_content(accounts.first.account_list_item)
        expect(page).to have_content(accounts.second.account_list_item)
      end
      expect(page).to have_content("No notifications are currently pending")

      click_link "Orders In Review"

      # Both orders are now in review
      expect(page).to have_content("OD ##{order_details.first.order_number}")
      expect(page).to have_content("OD ##{order_details.second.order_number}")
    end
  end

  it "shows a total cost at the bottom of the table" do
    login_as director
    visit facility_notifications_path(facility)

    within(".old-table tfoot") do
      expect(page).to have_selector("th", text: "Total", exact_text: true)
      expect(page).to have_selector("td", text: "$1.00", exact_text: true)
    end
  end

  describe "marking as reviewed" do
    before do
      order_details.each { |od| od.update!(reviewed_at: 1.week.from_now) }
    end

    it "can do a basic search on Orders in Review page" do
      login_as director
      visit facility_notifications_path(facility)
      click_link "Orders In Review"

      # Does not have default values for start/end
      expect(find_field("Start Date").value).to be_blank
      expect(find_field("End Date").value).to be_blank

      # Has both orders
      expect(page).to have_content("OD ##{order_details.first.order_number}")
      expect(page).to have_content("OD ##{order_details.second.order_number}")

      select accounts.first.account_list_item, from: "Payment Sources"
      click_button "Filter"

      # Has only the one from the selected account
      expect(page).to have_content("OD ##{order_details.first.order_number}")
      expect(page).not_to have_content("OD ##{order_details.second.order_number}")
    end

    it "can mark as reviewed and move them to the journal page" do
      login_as director
      visit facility_notifications_path(facility)
      click_link "Orders In Review"

      find("input[value='#{order_details.first.id}']").click
      find("input[value='#{order_details.second.id}']").click

      click_button "Mark as Reviewed"

      expect(page).to have_content("The selected orders have been marked as reviewed")
      expect(page).to have_content("No orders are currently in review")

      # The orders have moved on to the Journaling stage
      click_link "Create Journal"

      expect(page).to have_content("OD ##{order_details.first.order_number}")
      expect(page).to have_content("OD ##{order_details.second.order_number}")
    end
  end

end
