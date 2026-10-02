# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Building a public estimate", :js, feature_setting: { public_estimates: true, reload_routes: true } do
  let(:facility) { create(:setup_facility) }
  let!(:item) { create(:setup_item, facility:) }
  let!(:price_policy) do
    create(:item_price_policy, product: item, price_group: PriceGroup.base, unit_cost: 15, unit_subsidy: 0)
  end

  it "prices products without logging in" do
    visit root_path

    click_link "Get an Estimate"

    expect(page).to have_no_button("Calculate estimate")

    select "Internal", from: "customer_type"
    select facility.name, from: "facility_id"

    fill_in "quantities[#{item.id}]", with: 4
    click_button "Calculate estimate"

    expect(page).to have_content("Estimated cost")
    expect(page).to have_content("$60.00")
  end

  context "with a timed service" do
    let!(:timed_service) { create(:timed_service, facility:) }
    let!(:timed_service_price_policy) do
      create(
        :timed_service_price_policy,
        product: timed_service, price_group: PriceGroup.base, usage_rate: 60, usage_subsidy: 0
      )
    end

    it "prices a time based product from its duration" do
      visit estimate_path

      select "Internal", from: "customer_type"
      select facility.name, from: "facility_id"

      fill_in "durations[#{timed_service.id}]", with: 30
      click_button "Calculate estimate"

      expect(page).to have_content("Estimated cost")
      expect(page).to have_content("$30.00")
    end
  end
end
