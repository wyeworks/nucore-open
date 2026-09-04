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
