# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility Orders Search" do

  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:item2) { create(:setup_item, facility: facility) }
  let(:accounts) { create_list(:setup_account, 2) }
  let!(:orders) do
    accounts.map do |account|
      [create(:purchased_order, product: item, account: account),
       create(:purchased_order, product: item2, account: account)]
    end.flatten
  end

  let!(:completed_orders) do
    accounts.map do |account|
      [create(:complete_order, product: item, account: account),
       create(:complete_order, product: item2, account: account)]
    end.flatten
  end

  before do
    completed_orders.each do |order|
      order.order_details.first.update_attributes(price_policy: nil)
    end
  end

  context "new and in process orders tab" do
    it "can do a basic search" do
      login_as director
      visit facility_orders_path(facility)

      select item.to_s, from: "Products"
      click_button "Filter"
      expect(page).to have_css(".order-detail-description", text: item.name, count: 2)
      expect(page).not_to have_css(".order-detail-description", text: item2.name)
    end
  end

  context "problem orders tab" do
    it "can do a basic search" do
      login_as director
      visit show_problems_facility_orders_path(facility)

      select item.to_s, from: "Products"
      click_button "Filter"
      expect(page).to have_css("td", text: item.name, count: 2)
      expect(page).not_to have_css("td", text: item2.name)
    end
  end
end
