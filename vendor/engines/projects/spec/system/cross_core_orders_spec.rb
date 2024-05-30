# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Cross Core Orders", :js, feature_setting: { cross_core_order_view: true } do
  let(:facility) { create(:setup_facility) }
  let(:facility_administrator) { create(:user, :facility_administrator, facility:) }
  let(:item) { create(:setup_item, facility:) }
  let(:item2) { create(:setup_item, facility:) }
  let(:accounts) { create_list(:setup_account, 2) }

  before do
    login_as facility_administrator
  end

  let!(:cross_core_order_originating_facility) { create(:purchased_order, product: item, account: accounts.first) }
  let!(:order_for_facility) { create(:purchased_order, product: item, account: accounts.first) }

  let(:facility2) { create(:setup_facility) }
  let(:facility2_item) { create(:setup_item, facility: facility2) }
  let(:facility2_item2) { create(:setup_item, facility: facility2) }
  let!(:cross_core_order_originating_facility2) { create(:purchased_order, product: facility2_item, account: accounts.first) }

  let(:cross_core_project) { create(:project, facility:, name: "#{facility.abbreviation}-#{cross_core_order_originating_facility.id}") }
  let(:cross_core_project2) { create(:project, facility: facility2, name: "#{facility2.abbreviation}-#{cross_core_order_originating_facility2.id}") }

  let(:facility3) { create(:setup_facility) }
  let(:facility3_item) { create(:setup_item, facility: facility3) }
  let!(:cross_core_order_originating_facility3) { create(:purchased_order, product: facility3_item, account: accounts.first) }

  let!(:cross_core_orders) do
    [
      create(:purchased_order, cross_core_project:, product: facility2_item, account: accounts.last),
      create(:purchased_order, cross_core_project:, product: facility3_item, account: accounts.last),
      create(:purchased_order, cross_core_project: cross_core_project2, product: item, account: accounts.last),
      create(:purchased_order, cross_core_project: cross_core_project2, product: facility3_item, account: accounts.last),
    ]
  end

  before do
    cross_core_order_originating_facility.update!(cross_core_project:)
    cross_core_order_originating_facility.reload

    cross_core_order_originating_facility2.update!(cross_core_project: cross_core_project2)
    cross_core_order_originating_facility2.reload

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
      expect(page).to have_content(cross_core_order_originating_facility2.order_details.first)

      expect(page).not_to have_content(cross_core_orders[2].order_details.first)
      expect(page).not_to have_content(cross_core_order_originating_facility.order_details.first)
    end
  end

  context "when selecting All" do
    before do
      select "All", from: "Participating #{I18n.t("facilities_downcase")}"
      click_button "Filter"
    end

    it "shows all cross core orders placed for any facility" do
      expect(page).to have_content(cross_core_orders[0].order_details.first)
      expect(page).to have_content(cross_core_orders[1].order_details.first)
      expect(page).to have_content(cross_core_orders[2].order_details.first)
      expect(page).to have_content(cross_core_orders[3].order_details.first)

      expect(page).to have_content(cross_core_order_originating_facility2.order_details.first)
      expect(page).to have_content(cross_core_order_originating_facility.order_details.first)

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
      expect(page).to have_content(cross_core_order_originating_facility.order_details.first)

      expect(page).not_to have_content(cross_core_orders[0].order_details.first)
      expect(page).not_to have_content(cross_core_orders[1].order_details.first)
      expect(page).not_to have_content(cross_core_orders[3].order_details.first)
      expect(page).not_to have_content(cross_core_order_originating_facility2.order_details.first)
    end
  end
end
