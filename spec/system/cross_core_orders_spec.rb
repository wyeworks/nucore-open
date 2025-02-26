# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cross Core Orders", :js do
  # Defined in spec/support/contexts/cross_core_context.rb
  include_context "cross core orders"

  before do
    login_as facility_administrator

    visit cross_core_orders_facility_projects_path(facility)
  end

  it "shows no icons" do
    expect(page).to have_css(".fa-users", count: 0)
    expect(page).to have_css(".fa-building", count: 0)
  end

  context "when selecting Other - default" do
    it "shows all cross core orders placed for other facilities" do
      expect(page).to have_content(cross_core_orders[0].order_details.first)
      expect(page).to have_content(cross_core_orders[1].order_details.first)
      expect(page).to have_content(cross_core_orders[3].order_details.first)
      expect(page).to have_content(originating_order_facility2.order_details.first)

      expect(page).not_to have_content(cross_core_orders[2].order_details.first)
      expect(page).not_to have_content(originating_order_facility1.order_details.first)
    end
  end

  context "when selecting All" do
    before do
      select "All", from: "Participating #{I18n.t("facilities_downcase")}"
      click_button "Filter"
    end

    it "shows all cross core orders related to the current facility" do
      expect(page).to have_content(cross_core_orders[0].order_details.first)
      expect(page).to have_content(cross_core_orders[1].order_details.first)
      expect(page).to have_content(cross_core_orders[2].order_details.first)
      expect(page).to have_content(cross_core_orders[3].order_details.first)
      # This is from a cross core order that is not related to facility 1
      expect(page).not_to have_content(cross_core_orders[4].order_details.first)

      expect(page).to have_content(originating_order_facility2.order_details.first)
      expect(page).to have_content(originating_order_facility1.order_details.first)

      item_price_group = item.price_policies.first.price_group.name
      facility2_item_price_group = facility2_item.price_policies.first.price_group.name
      facility3_item_price_group = facility3_item.price_policies.first.price_group.name

      expect(page).to have_content(item_price_group, count: 2)
      expect(page).to have_content(facility2_item_price_group, count: 2)
      expect(page).to have_content(facility3_item_price_group, count: 2)
    end
  end

  context "when selecting Current" do
    before do
      select "Current", from: "Participating #{I18n.t("facilities_downcase")}"
      click_button "Filter"
    end

    it "shows only cross core orders placed for current facility" do
      expect(page).to have_content(cross_core_orders[2].order_details.first)
      expect(page).to have_content(originating_order_facility1.order_details.first)

      expect(page).not_to have_content(cross_core_orders[0].order_details.first)
      expect(page).not_to have_content(cross_core_orders[1].order_details.first)
      expect(page).not_to have_content(cross_core_orders[3].order_details.first)
      expect(page).not_to have_content(originating_order_facility2.order_details.first)
    end
  end
end
