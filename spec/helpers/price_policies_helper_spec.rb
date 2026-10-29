# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricePoliciesHelper do
  let(:price_group) { build_stubbed(:price_group, id: 0) }
  let(:price_policy) { build_stubbed(:instrument_usage_price_policy, product: nil) }

  describe "#charge_for_options" do
    let(:instrument) { build_stubbed(:instrument) }
    let(:options) { charge_for_options(instrument) }

    context "when the instrument is reservation-only" do
      before { allow(instrument).to receive(:reservation_only?).and_return(true) }

      it { expect(options).to eq([%w[Reservation reservation]]) }
    end

    context "when the instrument is not reservation-only" do
      before { allow(instrument).to receive(:reservation_only?).and_return(false) }

      it do
        expect(options).to match_array([
                                         %w[Overage overage], %w[Reservation reservation], %w[Usage usage]
                                       ])
      end
    end
  end

  describe "#display_usage_rate" do
    let(:usage_rate) { display_usage_rate(price_group, price_policy) }

    before(:each) do
      allow(price_policy).to receive(:hourly_usage_rate).and_return(BigDecimal("54.32"))
    end

    context "when params for the price group are present" do
      let(:params) do
        { price_policy_0: { usage_rate: "43.21" } }.with_indifferent_access
      end

      it "returns the usage rate from params" do
        expect(usage_rate).to eq("43.21")
      end
    end

    context "when params for the price group are not present" do
      it "returns the hourly_usage_rate, formatted" do
        expect(usage_rate).to eq("54.32")
      end
    end
  end

  describe "#display_usage_subsidy" do
    let(:usage_subsidy) { display_usage_subsidy(price_group, price_policy) }

    before(:each) do
      allow(price_policy).to receive(:hourly_usage_subsidy).and_return(BigDecimal("54.32"))
    end

    context "when params for the price group are present" do
      let(:params) do
        { price_policy_0: { usage_subsidy: "43.21" } }.with_indifferent_access
      end

      it "returns usage subsidy from params" do
        expect(usage_subsidy).to eq("43.21")
      end
    end

    context "when params for the price group are not present" do
      it "returns the hourly_usage_subsidy, formatted" do
        expect(usage_subsidy).to eq("54.32")
      end
    end
  end

  describe "#format_date"
  describe "#price_policies_path"
  describe "#price_policy_path"
end
