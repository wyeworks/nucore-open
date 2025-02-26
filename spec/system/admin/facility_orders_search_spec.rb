# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facility Orders Search" do
  let(:facility) { create(:setup_facility) }
  let(:director) { create(:user, :facility_director, facility: facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:item2) { create(:setup_item, facility: facility) }
  let(:accounts) { create_list(:setup_account, 2) }

  before do
    login_as director
  end

  context "same facility orders" do
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
        order.order_details.first.update(price_policy: nil)
      end
    end

    context "new and in process orders tab" do
      it "can do a basic search" do
        visit facility_orders_path(facility)

        select item.to_s, from: "Products"
        click_button "Filter"
        expect(page).to have_css(".order-detail-description", text: item.name, count: 2)
        expect(page).not_to have_css(".order-detail-description", text: item2.name)
      end
    end

    context "problem orders tab" do
      it "can do a basic search" do
        visit show_problems_facility_orders_path(facility)

        select item.to_s, from: "Products"
        click_button "Filter"
        expect(page).to have_css("td", text: item.name, count: 2)
        expect(page).not_to have_css("td", text: item2.name)
      end
    end
  end

  context "cross-core orders", :js do
    let!(:originating_cross_core_order) { create(:purchased_order, product: item, account: accounts.first) }
    let!(:order_for_facility) { create(:purchased_order, product: item, account: accounts.first) }

    let(:facility2) { create(:setup_facility) }
    let(:facility2_item) { create(:setup_item, facility: facility2) }
    let(:facility2_item2) { create(:setup_item, facility: facility2) }
    let!(:cross_core_order_originating_facility2) { create(:purchased_order, product: facility2_item, account: accounts.first) }

    let(:cross_core_project) { create(:project, facility:, name: "#{facility.abbreviation}-#{originating_cross_core_order.id}") }
    let(:cross_core_project2) { create(:project, facility: facility2, name: "#{facility2.abbreviation}-#{cross_core_order_originating_facility2.id}") }

    let(:originating_cross_core_order_path) { facility_order_path(originating_cross_core_order.facility, originating_cross_core_order) }
    let(:cross_core_orders_last_path) { facility_order_path(cross_core_orders.last.facility, cross_core_orders.last) }
    let(:order_for_facility_path) { facility_order_path(order_for_facility.facility, order_for_facility) }
    let(:cross_core_order_originating_facility2_path) { facility_order_path(cross_core_order_originating_facility2.facility, cross_core_order_originating_facility2) }
    let(:cross_core_orders_first_path) { facility_order_path(cross_core_orders.first.facility, cross_core_orders.first) }

    # First order originates in facility, second order originates in facility2
    let!(:cross_core_orders) do
      [
        create(:purchased_order, cross_core_project:, product: facility2_item, account: accounts.last),
        create(:purchased_order, cross_core_project: cross_core_project2, product: item, account: accounts.last),
      ]
    end

    before do
      originating_cross_core_order.update!(cross_core_project:)
      originating_cross_core_order.reload

      cross_core_order_originating_facility2.update!(cross_core_project: cross_core_project2)
      cross_core_order_originating_facility2.reload
    end

    context "New / In process tab" do
      before do
        visit facility_orders_path(facility)
      end

      context "when selecting Cross-Core" do
        before do
          select "Cross core", from: "Cross-Core"
          click_button "Filter"
        end

        it "shows only cross core orders placed for Facility" do
          expect(page).to have_css(".fa-users", count: 1) # cross_core_orders.last
          expect(page).to have_css(".fa-building", count: 1) # originating_cross_core_order

          expect(page).to have_link(originating_cross_core_order.id.to_s, href: originating_cross_core_order_path)
          expect(page).to have_link(cross_core_orders.last.id.to_s, href: cross_core_orders_last_path)

          expect(page).not_to have_link(order_for_facility.id.to_s, href: order_for_facility_path)
          expect(page).not_to have_link(cross_core_order_originating_facility2.id.to_s, href: cross_core_order_originating_facility2_path)
          expect(page).not_to have_link(cross_core_orders.first.id.to_s, href: cross_core_orders_first_path)
        end
      end

      context "when selecting All" do
        it "shows all orders placed for Facility" do
          expect(page).to have_css(".fa-users", count: 1) # cross_core_orders.last
          expect(page).to have_css(".fa-building", count: 1) # originating_cross_core_order

          expect(page).to have_link(order_for_facility.id.to_s, href: order_for_facility_path)
          expect(page).to have_link(originating_cross_core_order.id.to_s, href: originating_cross_core_order_path)
          expect(page).to have_link(cross_core_orders.last.id.to_s, href: cross_core_orders_last_path)

          expect(page).not_to have_link(cross_core_order_originating_facility2.id.to_s, href: cross_core_order_originating_facility2_path)
          expect(page).not_to have_link(cross_core_orders.first.id.to_s, href: cross_core_orders_first_path)
        end
      end
    end

    context "Problem orders tab" do
      let!(:cross_core_orders) do
        [
          create(:complete_order, cross_core_project:, product: facility2_item, account: accounts.last),
          create(:complete_order, cross_core_project: cross_core_project2, product: item, account: accounts.last),
        ]
      end

      let!(:order_for_facility) { create(:complete_order, product: item, account: accounts.first) }

      before do
        cross_core_orders.each do |order|
          order.order_details.first.update(price_policy: nil)
        end

        order_for_facility.order_details.first.update(price_policy: nil)

        visit show_problems_facility_orders_path(facility)
      end

      context "when selecting Cross-Core" do
        before do
          select "Cross core", from: "Cross-Core"
          click_button "Filter"
        end

        it "shows only cross core orders placed for Facility" do
          expect(page).to have_css(".fa-users", count: 1) # cross_core_orders.last
          expect(page).to have_css(".fa-building", count: 0)

          expect(page).to have_link(cross_core_orders.last.id.to_s, href: cross_core_orders_last_path)

          expect(page).not_to have_link(originating_cross_core_order.id.to_s, href: originating_cross_core_order_path)

          expect(page).not_to have_link(order_for_facility.id.to_s, href: order_for_facility_path)

          expect(page).not_to have_link(cross_core_order_originating_facility2.id.to_s, href: cross_core_order_originating_facility2_path)
          expect(page).not_to have_link(cross_core_orders.first.id.to_s, href: cross_core_orders_first_path)
        end
      end

      context "when selecting All" do
        it "shows all orders placed for Facility" do
          expect(page).to have_css(".fa-users", count: 1) # cross_core_orders.last
          expect(page).to have_css(".fa-building", count: 0) # order_for_facility is not a cross-core order so it doesn't have an icon

          expect(page).to have_link(order_for_facility.id.to_s, href: order_for_facility_path)
          expect(page).to have_link(cross_core_orders.last.id.to_s, href: cross_core_orders_last_path)

          expect(page).not_to have_link(originating_cross_core_order.id.to_s, href: originating_cross_core_order_path)
          expect(page).not_to have_link(cross_core_order_originating_facility2.id.to_s, href: cross_core_order_originating_facility2_path)
          expect(page).not_to have_link(cross_core_orders.first.id.to_s, href: cross_core_orders_first_path)
        end
      end
    end
  end
end
