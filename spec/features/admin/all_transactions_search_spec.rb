# frozen_string_literal: true

require "rails_helper"

RSpec.describe "All Transactions Search" do

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:accounts) { create_list(:setup_account, 2) }
  let!(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account: account) }
  end

  let(:order_detail) { orders.first.order_details.first }

  it "can do a basic search" do
    login_as director
    visit facility_transactions_path(facility)
    expected_default_date = 1.month.ago.beginning_of_month
    expect(page).to have_field("Start Date", with: I18n.l(expected_default_date.to_date, format: :usa))

    select accounts.first.account_list_item, from: "Payment Sources"
    click_button "Filter"
    expect(page).to have_link(order_detail.id.to_s, href: manage_facility_order_order_detail_path(facility, orders.first, orders.first.order_details.first))
    expect(page).not_to have_link(orders.second.order_details.first.id.to_s)
  end
end
