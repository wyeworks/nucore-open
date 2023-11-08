# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentPricePoliciesController do
  let(:facility) { create(:setup_facility) }
  let(:billing_mode) { "Default" }
  let(:pricing_mode) { "Schedule Rule" }
  let!(:instrument) { create(:instrument, facility:, billing_mode:, pricing_mode:) }
  let(:director) { create(:user, :facility_director, facility:) }

  let(:base_price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }
  let!(:cancer_center) { create(:price_group, :cancer_center) }

  before do
    login_as director
    facility.price_groups.destroy_all # get rid of the price groups created by the factories
  end

  context "Schedule Rule pricing mode" do
    it "can set up the price policies", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
      visit facility_instruments_path(facility, instrument)
      click_link instrument.name
      click_link "Pricing"
      click_link "Add Pricing Rules"

      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
      fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "120"
      fill_in "price_policy_#{base_price_group.id}[cancellation_cost]", with: "15"

      fill_in "price_policy_#{cancer_center.id}[usage_subsidy]", with: "30"

      fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "120.11"
      fill_in "price_policy_#{external_price_group.id}[minimum_cost]", with: "122"
      fill_in "price_policy_#{external_price_group.id}[cancellation_cost]", with: "31"

      fill_in "note", with: "This is my note"

      click_button "Add Pricing Rules"

      expect(page).to have_content("$60.00\n- $30.00\n= $30.00") # Cancer Center Usage Rate
      expect(page).to have_content("$120.00\n- $60.00\n= $60.00") # Cancer Center Minimum Cost
      expect(page).to have_content("$15.00", count: 2) # Internal and Cancer Center Reservation Costs

      # External price group
      expect(page).to have_content("$120.11")
      expect(page).to have_content("$122.00")
      expect(page).to have_content("$31.00")

      expect(page).to have_content("This is my note")
    end

    it "can only allow some to purchase", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
      visit facility_instruments_path(facility, instrument)
      click_link instrument.name
      click_link "Pricing"
      click_link "Add Pricing Rules"

      fill_in "note", with: "This is my note"

      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
      fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "120"
      fill_in "price_policy_#{base_price_group.id}[cancellation_cost]", with: "15"

      uncheck "price_policy_#{cancer_center.id}[can_purchase]"
      uncheck "price_policy_#{external_price_group.id}[can_purchase]"

      click_button "Add Pricing Rules"

      expect(page).to have_content(base_price_group.name)
      expect(page).not_to have_content(external_price_group.name)
      expect(page).not_to have_content(cancer_center.name)
    end

    describe "with required note enabled", feature_setting: { price_policy_requires_note: true, facility_directors_can_manage_price_groups: true } do
      it "requires the field" do
        visit facility_instruments_path(facility, instrument)
        click_link instrument.name
        click_link "Pricing"
        click_link "Add Pricing Rules"

        click_button "Add Pricing Rules"
        expect(page).to have_content("Note may not be blank")
      end
    end

    describe "with full cancellation cost enabled", :js, feature_setting: { charge_full_price_on_cancellation: true, facility_directors_can_manage_price_groups: true } do
      it "can set up the price policies", :js do
        visit facility_instruments_path(facility, instrument)
        click_link instrument.name
        click_link "Pricing"
        click_link "Add Pricing Rules"

        fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
        fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "120"
        fill_in "price_policy_#{base_price_group.id}[cancellation_cost]", with: "15"

        check "price_policy_#{base_price_group.id}[full_price_cancellation]"
        expect(page).to have_field("price_policy_#{base_price_group.id}[cancellation_cost]", disabled: true)

        fill_in "price_policy_#{cancer_center.id}[usage_subsidy]", with: "30"

        fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "120.11"
        fill_in "price_policy_#{external_price_group.id}[minimum_cost]", with: "122"
        fill_in "price_policy_#{external_price_group.id}[cancellation_cost]", with: "31"
        check "price_policy_#{external_price_group.id}[full_price_cancellation]"
        expect(page).to have_field("price_policy_#{external_price_group.id}[cancellation_cost]", disabled: true)

        fill_in "note", with: "This is my note"

        click_button "Add Pricing Rules"

        expect(page).to have_content("$60.00\n- $30.00\n= $30.00") # Cancer Center Usage Rate
        expect(page).to have_content("$120.00\n- $60.00\n= $60.00") # Cancer Center Minimum Cost
        expect(page).not_to have_content("$15.00")
        expect(page).to have_content(PricePolicy.human_attribute_name(:full_price_cancellation), count: 3)
      end
    end

    describe "with 'Nonbillable' billing mode enabled" do
      let(:billing_mode) { "Nonbillable" }

      it "does not allow adding, editing, or removing of price policies" do
        visit facility_instruments_path(facility, instrument)
        click_link instrument.name
        click_link "Pricing"
        expect(page).not_to have_content "Add Pricing Rules"

        expect(page).to have_content "Edit"
        expect(page).to have_no_link "Edit"

        expect(page).to have_content "Remove"
        expect(page).to have_no_link "Remove"
      end
    end

    describe "with 'Skip Review' billing mode enabled" do
      let(:billing_mode) { "Skip Review" }

      it "does not allow adding, editing, or removing of price policies" do
        visit facility_instruments_path(facility, instrument)
        click_link instrument.name
        click_link "Pricing"

        expect(page).not_to have_content "Add Pricing Rules"

        expect(page).to have_content "Edit"
        expect(page).to have_no_link "Edit"

        expect(page).to have_content "Remove"
        expect(page).to have_no_link "Remove"
      end
    end
  end

  context "Duration pricing mode" do
    let(:pricing_mode) { "Duration" }
    let!(:cannot_purchase_group) { create(:price_group, facility:) }

    it "can set up the price policies", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
      visit facility_instruments_path(facility, instrument)
      click_link instrument.name
      click_link "Pricing"
      click_link "Add Pricing Rules"

      fill_in "product[rate_starts_attributes][0][min_duration]", with: "2"
      fill_in "product[rate_starts_attributes][1][min_duration]", with: "3"
      fill_in "product[rate_starts_attributes][2][min_duration]", with: "4"

      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
      fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "120"
      fill_in "price_policy_#{base_price_group.id}[cancellation_cost]", with: "15"

      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "50"
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]", with: "40"
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][2][rate]", with: "30"

      fill_in "price_policy_#{cancer_center.id}[usage_subsidy]", with: "30"

      fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "120.11"
      fill_in "price_policy_#{external_price_group.id}[minimum_cost]", with: "122"
      fill_in "price_policy_#{external_price_group.id}[cancellation_cost]", with: "31"

      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][0][rate]", with: "110"
      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][1][rate]", with: "100"
      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][2][rate]", with: "90"

      uncheck "price_policy_#{cannot_purchase_group.id}[can_purchase]"

      fill_in "note", with: "This is my note"

      click_button "Add Pricing Rules"

      expect(page).to have_content("$60.00\n- $30.00\n= $30.00") # Cancer Center Usage Rate
      expect(page).to have_content("$120.00\n- $60.00\n= $60.00") # Cancer Center Minimum Cost
      expect(page).to have_content("$15.00", count: 2) # Internal and Cancer Center Reservation Costs

      # External price group
      expect(page).to have_content("$120.11")
      expect(page).to have_content("$122.00")
      expect(page).to have_content("$31.00")

      expect(page).to have_content("This is my note")
    end
  end

end
