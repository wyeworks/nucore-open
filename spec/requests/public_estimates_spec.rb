# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public estimates" do
  let(:facility) { create(:setup_facility) }
  let!(:item) { create(:setup_item, facility:) }
  let!(:internal_price_policy) do
    create(:item_price_policy, product: item, price_group: PriceGroup.base, unit_cost: 10, unit_subsidy: 0)
  end
  let!(:external_price_policy) do
    create(:item_price_policy, product: item, price_group: PriceGroup.external, unit_cost: 40, unit_subsidy: 0)
  end

  context "when the feature is enabled", feature_setting: { public_estimates: true, reload_routes: true } do
    it "is reachable without logging in" do
      get estimate_path

      expect(response).to have_http_status(:ok)
    end

    it "lists the products of the selected facility" do
      get estimate_path, params: { facility_id: facility.id }

      expect(response.body).to include(item.name)
    end

    it "prices the estimate for an internal customer" do
      get estimate_path, params: {
        customer_type: "base", facility_id: facility.id, quantities: { item.id.to_s => "2" }
      }

      expect(response.body).to include("$20.00")
    end

    it "prices the estimate for an external customer" do
      get estimate_path, params: {
        customer_type: "external", facility_id: facility.id, quantities: { item.id.to_s => "2" }
      }

      expect(response.body).to include("$80.00")
    end

    it "excludes bundles, which have no price policies of their own" do
      bundle = create(:bundle, facility:, bundle_products: [item])

      get estimate_path, params: { facility_id: facility.id }

      expect(response.body).to_not include(bundle.name)
    end

    it "prices the estimate with an extra configured customer type" do
      initial_types = Settings.public_estimates.customer_types
      initial_name = Settings.price_group.name.cancer_center
      Settings.public_estimates.customer_types = %w[base external cancer_center]
      Settings.price_group.name.cancer_center = "Cancer Center Rate"
      cancer_center = PriceGroup.setup_global(name: Settings.price_group.name.cancer_center, is_internal: false, display_order: 2)
      create(:item_price_policy, product: item, price_group: cancer_center, unit_cost: 25, unit_subsidy: 0)

      get estimate_path, params: {
        customer_type: "cancer_center", facility_id: facility.id, quantities: { item.id.to_s => "2" }
      }

      expect(response.body).to include("$50.00")
    ensure
      Settings.public_estimates.customer_types = initial_types
      Settings.price_group.name.cancer_center = initial_name
    end

    it "shows a print shortcut and the selected facility and customer type with the results" do
      get estimate_path, params: {
        customer_type: "external", facility_id: facility.id, quantities: { item.id.to_s => "1" }
      }

      printed = response.parsed_body.at_css(".show-for-print").text

      expect(response.body).to include("window.print()")
      expect(printed).to include(facility.name, "External")
    end

    it "lists a hidden product and prices it" do
      hidden = create(:setup_item, facility:, name: "Hidden Widget", is_hidden: true)
      create(:item_price_policy, product: hidden, price_group: PriceGroup.base, unit_cost: 5, unit_subsidy: 0)

      get estimate_path, params: {
        customer_type: "base", facility_id: facility.id, quantities: { hidden.id.to_s => "3" }
      }

      expect(response.body).to include(hidden.name)
      expect(response.body).to include("$15.00")
    end

    it "does not list an archived product" do
      archived = create(:setup_item, facility:, name: "Archived Widget", is_archived: true)

      get estimate_path, params: { customer_type: "base", facility_id: facility.id }

      expect(response.body).to_not include(archived.name)
    end

    it "does not list a product with no rate for the selected price group" do
      unpriced = create(:setup_item, facility:, name: "Unpriced Widget")

      get estimate_path, params: { customer_type: "base", facility_id: facility.id }

      expect(response.body).to include(item.name)
      expect(response.body).to_not include(unpriced.name)
    end

    it "ignores products with no quantity" do
      get estimate_path, params: {
        customer_type: "base", facility_id: facility.id, quantities: { item.id.to_s => "0" }
      }

      expect(response.body).to_not include("Estimated cost")
    end

    context "with a timed service" do
      let!(:timed_service) { create(:timed_service, facility:) }
      let!(:timed_service_price_policy) do
        create(
          :timed_service_price_policy,
          product: timed_service, price_group: PriceGroup.base, usage_rate: 60, usage_subsidy: 0
        )
      end

      it "prices it from the duration alone" do
        get estimate_path, params: {
          customer_type: "base",
          facility_id: facility.id,
          durations: { timed_service.id.to_s => "90" },
        }

        expect(response.body).to include("$90.00")
      end

      it "ignores time based products with no duration" do
        get estimate_path, params: {
          customer_type: "base",
          facility_id: facility.id,
          durations: { timed_service.id.to_s => "" },
        }

        expect(response.body).to_not include("Estimated cost")
      end

      it "ignores a quantity submitted for a time based product" do
        get estimate_path, params: {
          customer_type: "base",
          facility_id: facility.id,
          quantities: { timed_service.id.to_s => "2" },
        }

        expect(response.body).to_not include("Estimated cost")
      end

      it "offers a duration input but no quantity input" do
        get estimate_path, params: { customer_type: "base", facility_id: facility.id }

        expect(response.parsed_body.at_css("input[name='durations[#{timed_service.id}]']")).to be_present
        expect(response.parsed_body.at_css("input[name='quantities[#{timed_service.id}]']")).to be_nil
      end
    end

    context "with a daily booking instrument" do
      let!(:instrument) { create(:setup_instrument, :daily_booking, facility:) }
      let!(:instrument_price_policy) do
        create(
          :instrument_price_policy,
          product: instrument, price_group: PriceGroup.base, usage_rate_daily: 50, usage_subsidy_daily: 0
        )
      end

      it "prices it from a number of days" do
        get estimate_path, params: {
          customer_type: "base",
          facility_id: facility.id,
          durations: { instrument.id.to_s => "3" },
        }

        expect(response.body).to include("$150.00")
      end
    end

    it "offers a quantity input but no duration input for an item" do
      get estimate_path, params: { customer_type: "base", facility_id: facility.id }

      expect(response.parsed_body.at_css("input[name='quantities[#{item.id}]']")).to be_present
      expect(response.parsed_body.at_css("input[name='durations[#{item.id}]']")).to be_nil
    end
  end
end
