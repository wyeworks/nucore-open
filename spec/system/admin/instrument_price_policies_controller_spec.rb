# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentPricePoliciesController do
  let(:facility) { create(:setup_facility) }
  let(:billing_mode) { "Default" }
  let(:pricing_mode) { Instrument::Pricing::SCHEDULE_RULE }
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

      expect(page).to have_content("$60.00\n$30.00\n= $30.00") # Cancer Center Usage Rate
      expect(page).to have_content("$120.00\n$60.00\n= $60.00") # Cancer Center Minimum Cost
      expect(page).to have_content("$15.00", count: 2) # Internal and Cancer Center Reservation Costs

      # External price group
      expect(page).to have_content("$120.11")
      expect(page).to have_content("$122.00")
      expect(page).to have_content("$31.00")

      expect(page).to have_content("This is my note")

      expect(page).not_to have_content("Rate Start (hr):")
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

        expect(page).to have_content("$60.00\n$30.00\n= $30.00") # Cancer Center Usage Rate
        expect(page).to have_content("$120.00\n$60.00\n= $60.00") # Cancer Center Minimum Cost
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

    describe "with hidden price policies", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
      let(:item) { instrument }

      include_examples "with hidden price groups", "instrument"
    end
  end

  context "Duration pricing mode" do
    let(:pricing_mode) { Instrument::Pricing::DURATION }
    let!(:cannot_purchase_group) { create(:price_group, facility:) }

    it "can set up the price policies", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
      visit facility_instruments_path(facility, instrument)
      click_link instrument.name
      click_link "Pricing"
      click_link "Add Pricing Rules"

      fill_in "min_duration_0", with: "2"
      fill_in "min_duration_1", with: "3"
      fill_in "min_duration_2", with: "4"

      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
      fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "120"
      fill_in "price_policy_#{base_price_group.id}[cancellation_cost]", with: "15"

      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "50"
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]", with: "40"
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][2][rate]", with: "30"

      fill_in "price_policy_#{cancer_center.id}[usage_subsidy]", with: "25"
      fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][0][subsidy]", with: "20"
      fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][1][subsidy]", with: "10"
      fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][2][subsidy]", with: "5"

      fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "120.11"
      fill_in "price_policy_#{external_price_group.id}[minimum_cost]", with: "122"
      fill_in "price_policy_#{external_price_group.id}[cancellation_cost]", with: "31"

      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][0][rate]", with: "110"
      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][1][rate]", with: "100"
      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][2][rate]", with: "90"

      uncheck "price_policy_#{cannot_purchase_group.id}[can_purchase]"

      fill_in "note", with: "This is my note"

      click_button "Add Pricing Rules"

      expect(page).to have_content("$15.00", count: 2) # Internal and Cancer Center Reservation Costs

      # Cancer center
      expect(page).to have_content("$60.00\n$25.00\n= $35.00")    # Usage Rate
      expect(page).to have_content("$120.00\n$50.00\n= $70.00")   # Minimum Cost
      expect(page).to have_content("$50.00\n$20.00\n= $30.00")    # Step 2 rate
      expect(page).to have_content("$40.00\n$10.00\n= $30.00")    # Step 3 rate
      expect(page).to have_content("$30.00\n$5.00\n= $25.00")     # Step 4 rate

      # External price group
      expect(page).to have_content("$120.11")
      expect(page).to have_content("$122.00")
      expect(page).to have_content("$31.00")

      # Rate starts
      expect(page).to have_content("Over 2 hrs")
      expect(page).to have_content("Over 3 hrs")
      expect(page).to have_content("Over 4 hrs")

      # Base price group - Duration rates
      expect(page).to have_content("$50.00")
      expect(page).to have_content("$40.00")
      expect(page).to have_content("$25.00")

      # External price group - Duration rates
      expect(page).to have_content("$110.00")
      expect(page).to have_content("$100.00")
      expect(page).to have_content("$90.00")

      expect(page).to have_content("This is my note")
    end

    context "validations" do
      it "fails to save when duration rate is higher than base rate", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
        visit new_facility_instrument_price_policy_path(facility, instrument)

        fill_in "min_duration_0", with: "2"

        fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "70"

        uncheck "price_policy_#{cancer_center.id}[can_purchase]"
        uncheck "price_policy_#{external_price_group.id}[can_purchase]"
        uncheck "price_policy_#{cannot_purchase_group.id}[can_purchase]"

        fill_in "note", with: "This is my note"

        click_button "Add Pricing Rules"

        expect(page).to have_content("Duration rates base Rate must be lesser than or equal to Base rate")
      end

      it "fails to save when duration subsidy is higher than step rate", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
        visit new_facility_instrument_price_policy_path(facility, instrument)

        fill_in "min_duration_0", with: "2"
        fill_in "min_duration_1", with: "3"
        fill_in "min_duration_2", with: "4"

        fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "50"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]", with: "40"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][2][rate]", with: "30"

        fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][0][subsidy]", with: "60"
        fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][1][subsidy]", with: "20"
        fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][2][subsidy]", with: "0"

        uncheck "price_policy_#{external_price_group.id}[can_purchase]"
        uncheck "price_policy_#{cannot_purchase_group.id}[can_purchase]"

        fill_in "note", with: "This is my note"

        click_button "Add Pricing Rules"

        expect(page).to have_content("Subsidy must be lesser than or equal to step rate")
      end

      it "fails to save if not all steps are filled", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
        visit new_facility_instrument_price_policy_path(facility, instrument)

        fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "50"

        uncheck "price_policy_#{cancer_center.id}[can_purchase]"
        uncheck "price_policy_#{external_price_group.id}[can_purchase]"
        uncheck "price_policy_#{cannot_purchase_group.id}[can_purchase]"

        fill_in "note", with: "This is my note"

        click_button "Add Pricing Rules"
        expect(page).to have_content("Missing value for 'Rate start (hr)'")
      end

      it "fails to save duration rates do not have a rate start provided", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
        visit new_facility_instrument_price_policy_path(facility, instrument)

        fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "50"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]", with: "50"
        fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][2][rate]", with: "50"

        uncheck "price_policy_#{cancer_center.id}[can_purchase]"
        uncheck "price_policy_#{external_price_group.id}[can_purchase]"
        uncheck "price_policy_#{cannot_purchase_group.id}[can_purchase]"

        fill_in "note", with: "This is my note"

        click_button "Add Pricing Rules"

        expect(page).to have_content("Missing value for 'Rate start (hr)'")
      end
    end

    it "can edit price policies", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
      visit new_facility_instrument_price_policy_path(facility, instrument)

      fill_in "min_duration_0", with: "2"
      fill_in "min_duration_1", with: "3"
      fill_in "min_duration_2", with: "4"

      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
      fill_in "price_policy_#{base_price_group.id}[minimum_cost]", with: "120"
      fill_in "price_policy_#{base_price_group.id}[cancellation_cost]", with: "15"

      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "50"
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]", with: "40"
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][2][rate]", with: "30"

      fill_in "price_policy_#{cancer_center.id}[usage_subsidy]", with: "25"
      fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][0][subsidy]", with: "15"
      fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][1][subsidy]", with: "15"
      fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][2][subsidy]", with: "4"

      fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "120.11"
      fill_in "price_policy_#{external_price_group.id}[minimum_cost]", with: "122"
      fill_in "price_policy_#{external_price_group.id}[cancellation_cost]", with: "31"

      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][0][rate]", with: "110"
      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][1][rate]", with: "100"
      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][2][rate]", with: "90"

      expect(page).to have_content("/ minute")

      uncheck "price_policy_#{cannot_purchase_group.id}[can_purchase]"

      fill_in "note", with: "This is my note"

      click_button "Add Pricing Rules"

      expect(page).to have_content("Price Rules were successfully created.")

      click_link "Edit"

      expect(page).to have_field("min_duration_0", with: "2")
      expect(page).to have_field("min_duration_1", with: "3")
      expect(page).to have_field("min_duration_2", with: "4")

      expect(page).to have_field("price_policy_#{base_price_group.id}[duration_rates_attributes][0][rate]", with: "50.00")
      expect(page).to have_field("price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]", with: "40.00")
      expect(page).to have_field("price_policy_#{base_price_group.id}[duration_rates_attributes][2][rate]", with: "30.00")

      # Update values for Step 2
      fill_in "min_duration_1", with: "5"
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]", with: "20"

      ## START When values for Step 3 are removed, you can still save Step 1 and 2
      # Remove all values for Step 3
      fill_in "min_duration_2", with: ""
      fill_in "price_policy_#{base_price_group.id}[duration_rates_attributes][2][rate]", with: ""
      fill_in "price_policy_#{cancer_center.id}[duration_rates_attributes][2][subsidy]", with: ""
      fill_in "price_policy_#{external_price_group.id}[duration_rates_attributes][2][rate]", with: ""

      find_field("price_policy_#{base_price_group.id}[duration_rates_attributes][1][rate]").native.send_keys :tab # change focus to trigger the onchange event

      expect(page).to have_field("price_policy_#{cancer_center.id}[duration_rates_attributes][1][rate]", with: "20", type: :hidden)
      expect(page).to have_field("price_policy_#{external_price_group.id}[duration_rates_attributes][1][rate]", with: "100.00")

      click_button "Save Rules"

      expect(page).to have_content("Price Rules were successfully updated.")

      # Base rate start for Step 2 is updated
      expect(page).to have_content("Over 5 hrs")
      expect(page).not_to have_content("Over 3 hrs")

      # Rate start for Step 3 is removed
      expect(page).not_to have_content("Over 4 hrs")

      # Base price group - Duration rates
      expect(page).to have_content("$50.00")
      expect(page).not_to have_content("$30.00") # Step 3 rate (removed)

      # Duration rate for Step 2 is updated
      expect(page).not_to have_content("$40.00")
      expect(page).to have_content("$20.00")

      # Cancer Center subsidy
      expect(page).to have_content("$25.00")
      expect(page).not_to have_content("$4.00") # Step 3 subsidy (removed)

      # External
      expect(page).not_to have_content("$90.00") # Step 3 rate (removed)
    end

    describe "with hidden price policies", :js, feature_setting: { facility_directors_can_manage_price_groups: true } do
      let(:item) { instrument }

      include_examples "with hidden price groups", "instrument"
    end
  end

  context "External subsidy price groups", :js, feature_setting: { external_price_group_subsidies: true, facility_directors_can_manage_price_groups: true, charge_full_price_on_cancellation: true } do
    let!(:external_subsidy_group) { create(:price_group, facility: nil, is_internal: false, global: true, admin_editable: false, name: "External Subsidy", parent_price_group: external_price_group) }

    it "syncs fields from external parent (not base internal) and handles full cancellation correctly" do
      visit new_facility_instrument_price_policy_path(facility, instrument)

      fill_in "price_policy_#{base_price_group.id}[usage_rate]", with: "60"
      fill_in "price_policy_#{external_price_group.id}[usage_rate]", with: "120"

      # Verify external subsidy gets external rate (not base)
      expect(page).to have_field("price_policy_#{external_subsidy_group.id}[usage_rate]", with: "120", type: :hidden)

      # Check full cancellation on base - should NOT affect external subsidy
      check "price_policy_#{base_price_group.id}[full_price_cancellation]"
      expect(page).to have_field("price_policy_#{external_subsidy_group.id}[cancellation_cost]", disabled: false, type: :hidden)

      # Check full cancellation on external parent - SHOULD affect external subsidy
      check "price_policy_#{external_price_group.id}[full_price_cancellation]"
      expect(page).to have_field("price_policy_#{external_subsidy_group.id}[cancellation_cost]", disabled: true, type: :hidden)
    end
  end

  context "Schedule Rule Daily pricing mode", feature_setting: { facility_directors_can_manage_price_groups: true } do
    let(:pricing_mode) { Instrument::Pricing::SCHEDULE_DAILY }

    it "can add price policies", :js do
      visit new_facility_instrument_price_policy_path(facility, instrument)

      expect(page).to have_content("Rate Per Day")
      expect(page).to_not have_content("Rate Per Hour")

      expect(page).to_not have_content("Reservation Cost")
      expect(page).to_not have_content("Minimum Cost")

      PriceGroup.find_each do |price_group|
        expect(page).to_not have_field("price_policy_#{price_group.id}[minimum_cost]")
        expect(page).to_not have_field("price_policy_#{price_group.id}[cancellation]")
        expect(page).to_not have_field("price_policy_#{price_group.id}[usage_rate]")
      end

      fill_in("note", with: "Some note about pricing")

      check("price_policy_#{base_price_group.id}[can_purchase]")
      check("price_policy_#{cancer_center.id}[can_purchase]")
      uncheck("price_policy_#{external_price_group.id}[can_purchase]")

      fill_in("price_policy_#{base_price_group.id}[usage_rate_daily]", with: "100")
      fill_in("price_policy_#{cancer_center.id}[usage_subsidy_daily]", with: "30")

      find_field(
        "price_policy_#{cancer_center.id}[usage_rate_daily]",
        type: "hidden"
      ).tap do |hidden_input|
        expect(hidden_input.value).to eq("100")
      end

      expect(page).to_not have_content("/ minute")

      initial_count = instrument.price_policies.count
      click_button("Add Pricing Rules")

      expect(page).to(
        have_current_path(facility_instrument_price_policies_path(facility, instrument))
      )
      expect(page).to have_content("Price Rules were successfully created.")

      expect(instrument.price_policies.reload.count).to eq(initial_count + 3)
    end

    describe "already created price policies" do
      include ActiveSupport::NumberHelper

      let(:start_date) { Date.today }
      let(:expire_date) { PricePolicy.generate_expire_date(@start_date) }
      let(:base_price_policy) { instrument.price_policies.find_by(price_group: base_price_group) }
      let(:price_policies) { instrument.price_policies }

      before do
        PriceGroup.find_each do |price_group|
          create(
            :instrument_price_policy,
            product: instrument,
            price_group:
          )
        end
      end

      it "can view daily rates" do
        visit facility_instrument_price_policies_path(facility, instrument)

        expect(page).to have_content("Rate Per Day")
        expect(page).to_not have_content("Rate Per Hour")

        expect(page).to_not have_content("Reservation Cost")
        expect(page).to_not have_content("Minimum Cost")
      end

      it "can edit price policies" do
        visit edit_facility_instrument_price_policy_path(facility, instrument, start_date)

        expect(page).to have_content("Edit Pricing Rules")

        new_rate = BigDecimal("1081.99")
        fill_in("price_policy_#{base_price_group.id}[usage_rate_daily]", with: new_rate)

        expect { click_button("Save Rules") }.to(
          change do
            base_price_policy.reload.usage_rate_daily
          end.from(
            base_price_policy.usage_rate_daily
          ).to(
            new_rate
          )
        )

        expect(page).to have_content("Price Rules were successfully updated.")
        expect(page).to have_content(number_to_currency(new_rate))
      end

      it "can submit with errors, fix and re-submit" do
        visit edit_facility_instrument_price_policy_path(facility, instrument, start_date)

        new_rate = "99.90"
        new_subsidy = "79.78"

        fill_in("price_policy_#{base_price_group.id}[usage_rate_daily]", with: "value with error")
        fill_in("price_policy_#{cancer_center.id}[usage_subsidy_daily]", with: new_subsidy)

        click_button("Save Rules")

        expect(page).to have_content("There were problems with the following fields")

        fill_in("price_policy_#{base_price_group.id}[usage_rate_daily]", with: new_rate)

        click_button("Save Rules")

        expect(page).to have_content("Price Rules were successfully updated.")
        expect(page).to have_content(number_to_currency(new_rate))
        expect(page).to have_content(number_to_currency(new_subsidy))
      end
    end
  end
end
