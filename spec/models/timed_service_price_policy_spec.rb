# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimedServicePricePolicy do
  describe "#calculate_cost_and_subsidy_from_order_detail" do
    let(:product) { build_stubbed(:timed_service) }
    let(:price_policy) do
      build_stubbed(
        :timed_service_price_policy,
        product: product,
        usage_rate: 60,
        usage_subsidy: 15,
        minimum_cost: 10,
      )
    end
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
      it { is_expected.to eq(cost: 10, subsidy: 2.5) }
    end
  end

  describe "with duration (stepped) pricing" do
    let(:facility) { create(:setup_facility) }
    let(:price_group) { create(:price_group, facility:) }
    let(:product) do
      create(:timed_service, facility:, pricing_mode: TimedService::Pricing::DURATION)
    end
    let(:price_policy) do
      create(:timed_service_price_policy, product:, price_group:, usage_rate: 120, usage_subsidy: 30)
    end

    before do
      create(:duration_rate, price_policy:, min_duration_hours: 2, rate: 60, subsidy: 12)
    end

    subject(:costs) { price_policy.calculate_cost_and_subsidy_from_order_detail(order_detail) }

    describe "with a duration below the first step" do
      let(:order_detail) { build_stubbed(:order_detail, product:, quantity: 60) }

      it { is_expected.to eq(cost: 120, subsidy: 30) }
    end

    describe "with a duration spanning the step boundary" do
      let(:order_detail) { build_stubbed(:order_detail, product:, quantity: 180) }

      # Cost:    120 min @ $2.00 = $240, then 60 min @ $1.00 = $60
      # Subsidy: 120 min @ $0.50 = $60,  then 60 min @ $0.20 = $12
      it { is_expected.to eq(cost: 300, subsidy: 72) }
    end

    describe "when the product is not in duration pricing mode" do
      let(:product) { create(:timed_service, facility:) }
      let(:order_detail) { build_stubbed(:order_detail, product:, quantity: 180) }

      it "ignores the duration rates and charges the flat rate" do
        is_expected.to eq(cost: 360, subsidy: 90)
      end
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
