# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Building a public estimate", feature_setting: { public_estimates: true, reload_routes: true } do
  let(:facility) { create(:setup_facility) }
  let!(:item) { create(:setup_item, facility:) }
  let!(:price_policy) do
    create(:item_price_policy, product: item, price_group: PriceGroup.base, unit_cost: 15, unit_subsidy: 0)
  end

  it "prices products without logging in" do
    visit root_path

    click_link "Get an Estimate"

    select "Internal", from: "customer_type"
    select facility.name, from: "facility_id"
    click_button "Select facility"

    fill_in "quantities[#{item.id}]", with: 4
    click_button "Calculate estimate"

    expect(page).to have_content("Estimated cost")
    expect(page).to have_content("$60.00")
  end
end
