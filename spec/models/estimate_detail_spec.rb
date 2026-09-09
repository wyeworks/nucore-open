# frozen_string_literal: true

require "rails_helper"

RSpec.describe EstimateDetail do
  let(:facility) { create(:setup_facility) }
  let(:price_group) { facility.price_groups.first }
  let!(:item) { create(:setup_item, facility:) }
  let!(:item_price_policy) do
    create(:item_price_policy, product: item, price_group:, unit_cost: 25, unit_subsidy: 5)
  end

  describe "#assign_price_policy_and_cost without a user" do
    let(:persisted_detail) do
      estimate = create(:estimate, facility:, price_group:)
      estimate.estimate_details.create!(product: item, quantity: 3)
    end

    let(:anonymous_detail) do
      estimate = Estimate.new(facility:, price_group:)
      estimate.estimate_details.build(product: item, quantity: 3)
    end

    it "resolves the price policy on an unsaved record" do
      expect(anonymous_detail.assign_price_policy_and_cost).to be true
      expect(anonymous_detail.price_policy).to eq(item_price_policy)
    end

    it "computes the same cost as the persisted equivalent" do
      anonymous_detail.assign_price_policy_and_cost

      expect(anonymous_detail.cost).to eq(persisted_detail.cost)
      expect(anonymous_detail.cost).to eq(60)
    end

    it "persists nothing" do
      expect { anonymous_detail.assign_price_policy_and_cost }.not_to change(EstimateDetail, :count)
      expect(anonymous_detail).not_to be_persisted
    end

    it "returns false when no price policy matches the price group" do
      other_item = create(:setup_item, facility:)
      detail = Estimate.new(facility:, price_group:).estimate_details.build(product: other_item, quantity: 1)

      expect(detail.assign_price_policy_and_cost).to be false
    end
  end
end
