# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Moving transactions between accounts" do

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:user) { create(:user) }
  let(:accounts) { create_list(:setup_account, 2, :with_account_owner, owner: user) }
  let(:other_account) { create(:setup_account) }
  let(:orders) do
    (accounts + [other_account]).map { |account| create(:complete_order, product: item, account: account) }
  end
  let!(:order_details) { orders.flat_map(&:order_details) }

  before do
    order_details.each { |od| od.update(note: "OD ##{od.order_number}") }
  end

  it "can do a basic search" do
    login_as director
    visit facility_movable_transactions_path(facility)

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

  it "can move transactions to another account" do
    login_as director
    visit facility_movable_transactions_path(facility)

    order_details.each do |od|
      find("input[value='#{od.id}']").click
    end

    click_button "Reassign Chart Strings"

    expect(page).to have_content("All chart strings listed above are available")

    select accounts.first.account_list_item, from: "Payment Source"
    click_button "Reassign Chart String"

    expect(page).to have_content("Confirm Transaction Moves")

    # Because other_account's order detail cannot be moved
    expect(page).to have_content("Transactions that will not be moved:")

    click_button "Reassign Chart String"

    within(".notice") do
      expect(page).to have_content "2 transactions were reassigned"
    end

    expect(order_details.map(&:reload).map(&:account)).to eq([accounts.first, accounts.first, other_account])
  end

  it "Renders when problem orders" do
    # E.g. missing a price policy
    order_details.first.update!(actual_cost: nil, actual_subsidy: nil, estimated_cost: nil, estimated_subsidy: nil)

    login_as director
    visit facility_movable_transactions_path(facility)

    order_details.each do |od|
      find("input[value='#{od.id}']").click
    end

    click_button "Reassign Chart Strings"

    expect(page).to have_content("All chart strings listed above are available")

    select accounts.first.account_list_item, from: "Payment Source"
    click_button "Reassign Chart String"

    expect(page).to have_content("Confirm Transaction Moves")

    click_button "Reassign Chart String"
    expect(order_details.map(&:reload).map(&:account)).to eq([accounts.first, accounts.first, other_account])
  end
end
