# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Transactions Search" do

  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:item2) { create(:setup_item, facility: facility) }
  let(:user) { create(:user) }
  let(:accounts) { create_list(:setup_account, 2, owner: user) }
  let!(:orders) do
    accounts.map do |account|
      [create(:purchased_order, product: item, account: account),
       create(:purchased_order, product: item2, account: account)]
    end.flatten
  end

  context "index" do
    let!(:completed_orders) do
      accounts.map do |account|
        [create(:complete_order, product: item, account: account),
         create(:complete_order, product: item2, account: account)]
      end.flatten
    end

    it "can do a basic search" do
      login_as user
      visit transactions_path

      select accounts.first.description, from: "Payment Sources"
      click_button "Filter"
      expect(page).to have_css("td", text: accounts.first.description, count: 2)
      expect(page).not_to have_css("td", text: accounts.last.description, count: 2)
    end
  end

  context "in review" do

    let!(:orders_in_review) do
      accounts.map do |account|
        [create(:complete_order, product: item, account: account),
         create(:complete_order, product: item2, account: account)]
      end.flatten
    end

    before do
      orders_in_review.flat_map(&:order_details).each do |od|
        od.update(reviewed_at: 7.days.from_now)
      end
    end

    it "can do a basic search" do
      login_as user
      visit transactions_path

      select accounts.first.description, from: "Payment Sources"
      click_button "Filter"
      expect(page).to have_css("td", text: accounts.first.description, count: 2)
      expect(page).not_to have_css("td", text: accounts.last.description, count: 2)
    end
  end

end
