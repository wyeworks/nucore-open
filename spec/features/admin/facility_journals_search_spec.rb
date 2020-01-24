# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Journals Search" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:accounts) { create_list(:setup_account, 2) }
  let(:orders) do
    accounts.map { |account| create(:complete_order, product: item, account: account) }
  end

  let(:order_details) { orders.map(&:order_details).flatten }

  before do
    order_details.each do |detail|
      detail.update(reviewed_at: 1.day.ago)
    end
  end

  it "can do a basic filter" do
    login_as director
    visit new_facility_journal_path(facility)
    select accounts.first.account_list_item, from: "Payment Sources"
    click_button "Filter"

    expect(page).to have_link(order_details.first.id.to_s, href: manage_facility_order_order_detail_path(facility, orders.first, order_details.first))
    expect(page).not_to have_link(order_details.second.id.to_s, href: manage_facility_order_order_detail_path(facility, orders.second, order_details.second))
  end
end
