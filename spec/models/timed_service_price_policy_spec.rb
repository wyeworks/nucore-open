# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimedServicePricePolicy do
  describe "#calculate_cost_and_subsidy_from_order_detail" do
    let(:product) { build_stubbed(:timed_service) }
    let(:price_policy) { build_stubbed(:timed_service_price_policy, product: product, usage_rate: 60, usage_subsidy: 15) }
    subject(:costs) { price_policy.calculate_cost_and_subsidy_from_order_detail(order_detail) }

    describe "with an hour of usage" do
      let(:order_detail) { build_stubbed(:order_detail, product: product, quantity: 60) }
      it { is_expected.to eq(cost: 60, subsidy: 15) }
    end

    describe "with 25 minutes of usage" do
      let(:order_detail) { build_stubbed(:order_detail, product: product, quantity: 25) }
      it { is_expected.to eq(cost: 25, subsidy: 6.25) }
    end

    describe "with 0 minutes of usage" do
      let(:order_detail) { build_stubbed(:order_detail, product: product, quantity: 0) }
      it { is_expected.to eq(cost: 0, subsidy: 0) }
    end
  end

  describe "#estimate_cost_from_estimate_detail" do
    let(:product) { build_stubbed(:timed_service) }
    let(:price_policy) { build_stubbed(:timed_service_price_policy, product: product, usage_rate: 60, usage_subsidy: 15) }
    let(:estimate_detail) { double("EstimateDetail", duration: 60, quantity: 2) }

    it "returns the net cost (cost minus subsidy) times quantity" do
      expect(price_policy.estimate_cost_from_estimate_detail(estimate_detail)).to eq((60 - 15) * 2)
    end
  end
end
