# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRoomPricePolicy do
  describe "#calculate_cost_and_subsidy_from_order_detail" do
    let(:product) { create(:secure_room) }
    let!(:schedule_rule) { create(:schedule_rule, :all_day, product: product) }
    let(:order_detail) { build_stubbed(:order_detail, product: product, occupancy: occupancy) }
    let(:price_policy) { build_stubbed(:secure_room_price_policy, product: product, usage_rate: 60, usage_subsidy: 15, minimum_cost: 30) }
    subject(:costs) { price_policy.calculate_cost_and_subsidy_from_order_detail(order_detail) }

    describe "with an hour of usage" do
      let(:occupancy) { build_stubbed(:occupancy, entry_at: 1.hour.ago, exit_at: Time.current) }
      it { is_expected.to eq(cost: 60, subsidy: 15) }
    end

    describe "with 24 hours of usage" do
      let(:occupancy) { build_stubbed(:occupancy, entry_at: 24.hours.ago, exit_at: Time.current) }
      it { is_expected.to eq(cost: 1440, subsidy: 360) }
    end

    describe "with less than the minimum usage" do
      let(:occupancy) { build_stubbed(:occupancy, entry_at: 15.minutes.ago, exit_at: Time.current) }
      it { is_expected.to eq(cost: 30, subsidy: 7.5) }
    end

    describe "with an orphaned occupancy" do
      let(:occupancy) { build_stubbed(:occupancy, entry_at: 1.day.ago, exit_at: nil) }
      it { is_expected.to be_blank }
    end

    describe "with an exit-only occupancy" do
      let(:occupancy) { build_stubbed(:occupancy, entry_at: nil, exit_at: 1.day.ago) }
      it { is_expected.to be_blank }
    end

    describe "with a discount" do
      let!(:schedule_rule) { create(:schedule_rule, :all_day, product: product, discount_percent: 10) }

      describe "rounding seconds" do
        let(:occupancy) { build_stubbed(:occupancy, entry_at: 1.hour.ago + 15.seconds, exit_at: Time.current) }

        it { is_expected.to eq(cost: 54, subsidy: 13.5) }
      end
    end
  end
end
