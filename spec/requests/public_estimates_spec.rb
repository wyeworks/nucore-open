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
  let(:estimate_result_html) do
    response.parsed_body.at_css(".estimate-result")&.text
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

    context "when ther're extra customer types" do
      let(:new_customer_types) { %w[base external cancer_center] }

      before do
        allow(Settings.public_estimates).to receive(:customer_types) { new_customer_types }
        allow(Settings.price_group.name).to receive(:cancer_center) { "Cancer Center Rate" }
        cancer_center = PriceGroup.setup_global(name: Settings.price_group.name.cancer_center, is_internal: false, display_order: 2)
        create(:item_price_policy, product: item, price_group: cancer_center, unit_cost: 25, unit_subsidy: 0)
      end

      it "prices the estimate with an extra configured customer type" do
        get estimate_path, params: {
          customer_type: "cancer_center", facility_id: facility.id, quantities: { item.id.to_s => "2" }
        }

        expect(response.body).to include("$50.00")
      end
    end

    it "shows a print shortcut and the selected facility and customer type with the results" do
      get estimate_path, params: {
        customer_type: "external", facility_id: facility.id, quantities: { item.id.to_s => "1" }
      }

      expect(response.body).to include("window.print()")
      expect(estimate_result_html).to include(facility.name, "External")
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

    it "displays the note in the estimate results" do
      get estimate_path, params: {
        customer_type: "base",
        facility_id: facility.id,
        quantities: { item.id.to_s => "2" },
        note: "Test note for estimate",
      }

      expect(estimate_result_html).to include("Test note for estimate")
    end

    it "displays empty note when none is provided" do
      get estimate_path, params: {
        customer_type: "base",
        facility_id: facility.id,
        quantities: { item.id.to_s => "2" },
      }

      expect(estimate_result_html).to include(Estimate.human_attribute_name(:note))
    end

    context "when time based product duration is nil" do
      let!(:timed_service) do
        create(:timed_service, facility:)
      end

      it "ignores time based products with no duration" do
        get estimate_path, params: {
          customer_type: "base",
          facility_id: facility.id,
          quantities: { timed_service.id.to_s => "1" },
        }

        expect(page).not_to have_text("Estimated cost")
      end
    end
  end
end
