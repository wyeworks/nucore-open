# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricePolicies::TimeBasedPriceCalculator do

  let(:product) { create(:setup_instrument, skip_schedule_rules: true) }
  let!(:day_schedule) { create(:schedule_rule, :weekday, product: product) }
  let!(:night_schedule) { create(:schedule_rule, :weekday, :evening, discount_percent: 10, product: product) }
  let!(:weekend_schedule) { create(:schedule_rule, :weekend, :all_day, discount_percent: 25, product: product) }
  let(:calculator) { described_class.new(price_policy) }
  let(:price_policy) { build_stubbed(:instrument_price_policy, options.merge(product: product)) }
  let(:options) { {} }

  describe "#calculate" do
    subject(:costs) { calculator.calculate(start_at, end_at) }

    describe "with no subsidies" do
      let(:options) { { usage_rate: 60 } }

      describe "when it is all in one schedule rule" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
        let(:end_at) { start_at + 1.hour }
        it { is_expected.to eq(cost: 60, subsidy: 0) }
      end

      describe "when it is all in one discounted rule" do
        let(:start_at) { Time.zone.local(2017, 4, 29, 12, 0) } # Saturday
        let(:end_at) { start_at + 1.hour }
        it { is_expected.to eq(cost: 45, subsidy: 0) }
      end

      describe "when it overlaps into the evening" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 16, 0) }
        let(:end_at) { start_at + 2.hours }
        it { is_expected.to eq(cost: 60 + 54, subsidy: 0) }
      end

      describe "when it overlaps into the weekend" do
        let(:start_at) { Time.zone.local(2017, 4, 28, 16, 0) }
        let(:end_at) { Time.zone.local(2017, 4, 29, 2, 0) } # Saturday 2am
        # 1 hour  @ $60 * 0%    = $60   Normal
        # 7 hours @ $60 * 10%   = $378  Evening
        # 2 hours @ $60 * 25%   = 90    Weekend
        it { is_expected.to eq(cost: 60 + 378 + 90, subsidy: 0) }
      end
    end

    describe "with subsidies" do
      let(:options) { { usage_rate: 60, usage_subsidy: 15 } }
      describe "when it is all in one schedule rule" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
        let(:end_at) { start_at + 1.hour }
        it { is_expected.to eq(cost: 60, subsidy: 15) }
      end

      describe "when it is all in one discounted rule" do
        let(:start_at) { Time.zone.local(2017, 4, 29, 12, 0) } # Saturday
        let(:end_at) { start_at + 1.hour }
        it { is_expected.to eq(cost: 45, subsidy: 11.25) }
      end

      describe "when it overlaps into the evening" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 16, 0) }
        let(:end_at) { start_at + 2.hours }
        it { is_expected.to eq(cost: 60 + 54, subsidy: 28.5) }
      end

      describe "when it overlaps into the weekend" do
        let(:start_at) { Time.zone.local(2017, 4, 28, 16, 0) }
        let(:end_at) { Time.zone.local(2017, 4, 29, 2, 0) } # Saturday 2am
        # 1 hour  @ $60 * 0%    = $60   Normal
        # 7 hours @ $60 * 10%   = $378  Evening
        # 2 hours @ $60 * 25%   = 90    $Weekend
        it { is_expected.to eq(cost: 60 + 378 + 90, subsidy: 132) }
      end
    end

    describe "with higher precision" do
      # $31/60 = .5167
      # $17/60 = .2833
      let(:options) { { usage_rate: 31, usage_subsidy: 17 } }

      describe "with no discount" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) } # Thursday
        let(:end_at) { start_at + 13.minutes }
        it { is_expected.to eq(cost: 6.71666671, subsidy: 3.68333329) }
      end

      describe "with the weekend discount of 25%" do
        let(:start_at) { Time.zone.local(2017, 4, 29, 12, 0) } # Saturday
        let(:end_at) { start_at + 13.minutes }
        it { is_expected.to eq(cost: 5.0375000325, subsidy: 2.7624999675) }
      end
    end

    describe "with a minimum cost" do
      let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) } # Thursday

      describe "with rate and subsidy" do
        let(:options) { { usage_rate: 60, usage_subsidy: 10, minimum_cost: 30 } }

        describe "when you are below the minimum" do
          let(:end_at) { start_at + 29.minutes }
          it { is_expected.to eq(cost: 30, subsidy: 5.0000001) }
        end

        describe "when you are above the minimum" do
          let(:end_at) { start_at + 31.minutes }
          it { is_expected.to eq(cost: 31, subsidy: 5.16666677) }
        end
      end

      describe "with zero cost" do
        let(:options) { { usage_rate: 0, minimum_cost: 30 } }
        describe "when you use it for an hour" do
          let(:end_at) { start_at + 1.hour }
          it { is_expected.to eq(cost: 30, subsidy: 0) }
        end

        describe "when you use for a day" do
          let(:end_at) { start_at + 1.day }
          it { is_expected.to eq(cost: 30, subsidy: 0) }
        end
      end
    end

    describe "with seconds" do
      let(:options) { { usage_rate: 60 } }

      describe "when within the same minute" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0, 10) } # Thursday
        let(:end_at) { Time.zone.local(2017, 4, 27, 12, 0, 20) } # Thursday
        it "charges for one minute" do
          expect(costs).to eq(cost: 1, subsidy: 0)
        end
      end

      describe "when spans two minutes, but less than a minute" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0, 50) } # Thursday
        let(:end_at) { Time.zone.local(2017, 4, 27, 12, 1, 10) } # Thursday
        it "charges for one minute because the seconds are stripped off" do
          expect(costs).to eq(cost: 1, subsidy: 0)
        end
      end

      describe "when going across 3 minutes" do
        let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0, 0) } # Thursday
        let(:end_at) { Time.zone.local(2017, 4, 27, 12, 2, 50) } # Thursday
        it "charges for two minutes because the seconds are stripped off" do
          expect(costs).to eq(cost: 2, subsidy: 0)
        end
      end
    end

    describe "invalid times" do
      let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) } # Thursday
      let(:end_at) { start_at - 1.hour }

      it { is_expected.to be_nil }
    end
  end

  describe "#calculate_discount" do
    subject(:discount) { calculator.calculate_discount(start_at, end_at) }

    describe "when the entire time is within a zero discount" do
      let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
      let(:end_at) { Time.zone.local(2017, 4, 27, 14, 0) }
      it { is_expected.to eq(1) }
    end

    describe "when it overlaps into evening" do
      let(:start_at) { Time.zone.local(2017, 4, 27, 16, 0) }

      describe "one hour in zero percent, one hour in 10%" do
        let(:end_at) { Time.zone.local(2017, 4, 27, 18, 0) }
        it { is_expected.to eq(0.95) }
      end

      describe "one hour in zero percent, and three hours in 10%" do
        let(:end_at) { Time.zone.local(2017, 4, 27, 20, 0) }
        it { is_expected.to eq(0.925) }
      end
    end

    describe "when it overlaps multiple schedule rules" do
      # Friday at 4pm
      let(:start_at) { Time.zone.local(2017, 4, 28, 16, 0) }
      # Saturday at 2am
      let(:end_at) { Time.zone.local(2017, 4, 29, 2, 0) }
      # 1 hour in 0%, 7 hours in 10%, 2 hours in 25%
      it { is_expected.to eq(0.88) }
    end

  end

end
