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
      get "/estimate"

      expect(response).to have_http_status(:ok)
    end

    it "lists the products of the selected facility" do
      get "/estimate", params: { facility_id: facility.id }

      expect(response.body).to include(item.name)
    end

    it "prices the estimate for an internal customer" do
      get "/estimate", params: {
        customer_type: "internal", facility_id: facility.id, quantities: { item.id.to_s => "2" }
      }

      expect(response.body).to include("$20.00")
    end

    it "prices the estimate for an external customer" do
      get "/estimate", params: {
        customer_type: "external", facility_id: facility.id, quantities: { item.id.to_s => "2" }
      }

      expect(response.body).to include("$80.00")
    end

    it "reports products with no rate for the selected price group" do
      unpriced = create(:setup_item, facility:)

      get "/estimate", params: {
        customer_type: "internal", facility_id: facility.id, quantities: { unpriced.id.to_s => "1" }
      }

      expect(response.body).to include("No public rate available")
    end

    it "excludes bundles, which have no price policies of their own" do
      bundle = create(:bundle, facility:, bundle_products: [item])

      get "/estimate", params: { facility_id: facility.id }

      expect(response.body).to_not include(bundle.name)
    end

    it "prices the estimate with a second external group when one is configured" do
      initial = Settings.price_group.name.external_2
      Settings.price_group.name.external_2 = "External Non-Profit Rate"
      non_profit = PriceGroup.setup_global(name: "External Non-Profit Rate", is_internal: false, display_order: 2)
      create(:item_price_policy, product: item, price_group: non_profit, unit_cost: 25, unit_subsidy: 0)

      get "/estimate", params: {
        customer_type: "external_non_profit", facility_id: facility.id, quantities: { item.id.to_s => "2" }
      }

      expect(response.body).to include("$50.00")
    ensure
      Settings.price_group.name.external_2 = initial
    end

    it "offers no quantity field for a product with no rate for the selected price group" do
      unpriced = create(:setup_item, facility:, name: "Unpriced Widget")

      get "/estimate", params: { customer_type: "internal", facility_id: facility.id }

      expect(response.body).to include(unpriced.name)
      expect(response.body).to_not include(%(name="quantities[#{unpriced.id}]"))
      expect(response.body).to include(%(name="quantities[#{item.id}]"))
    end

    it "ignores products with no quantity" do
      get "/estimate", params: {
        customer_type: "internal", facility_id: facility.id, quantities: { item.id.to_s => "0" }
      }

      expect(response.body).to_not include("Estimated cost")
    end
  end

  context "when the feature is disabled", feature_setting: { public_estimates: false, reload_routes: true } do
    it "does not route" do
      get "/estimate"

      expect(response).to have_http_status(:not_found)
    end
  end
end
