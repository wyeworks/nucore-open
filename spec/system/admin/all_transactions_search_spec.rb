# frozen_string_literal: true

require "rails_helper"

RSpec.describe "All Transactions Search", :js do
  # Defined in spec/support/contexts/cross_core_context.rb
  include_context "cross core orders"

  let(:director) { create(:user, :facility_director, facility: facility) }
  let!(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account: account) }
  end

  let(:order_detail) { orders.first.order_details.first }

  before do
    all_cross_core_orders.each do |order|
      order.order_details.each(&:complete!)
    end
  end

  it "can do a basic search" do
    login_as director
    visit facility_transactions_path(facility)
    expected_default_date = 1.month.ago.beginning_of_month
    expect(page).to have_field("Start Date", with: I18n.l(expected_default_date.to_date, format: :usa))

    select_from_chosen accounts.second.account_list_item, from: "Payment Sources"
    click_button "Filter"
    
    expect(page).to have_content("Total")
    expect(page).not_to have_link(order_detail.id.to_s)
    expect(page).to have_link(orders.second.order_details.first.id.to_s)

    # Cross Core orders
    expect(page).not_to have_link(originating_order_facility1.id)
    expect(page).to have_link(cross_core_orders[2].id)
    expect(page).to have_css(".fa-users", count: 1) # cross_core_orders[2] is a cross-core order that didn't originate in the current facility
  end

  it "is accessible", :js do
    login_as director
    visit facility_transactions_path(facility)

    # Skip these two violations because the chosen JS library is hard to make accessible
    expect(page).to be_axe_clean.skipping("label", "select-name")
  end

  it "does not show the Participating Facilities filter" do
    login_as director
    visit transactions_path

    expect(page).to have_content("Transaction History")
    expect(page).not_to have_content("Participating Facilities")
  end
end
