# frozen_string_literal: true

require "rails_helper"

RSpec.describe PricePolicies::TimeBasedPriceCalculator do

  let(:calculator) { described_class.new(price_policy) }
  let(:price_policy) { build_stubbed(:instrument_price_policy, options.merge(product: product)) }
  let(:options) { {} }

  context "when product has schedule rules pricing mode" do
    let(:product) { create(:setup_instrument, skip_schedule_rules: true) }
    let!(:day_schedule) { create(:schedule_rule, :weekday, product: product) }
    let!(:night_schedule) { create(:schedule_rule, :weekday, :evening, discount_percent: 10, product: product) }
    let!(:weekend_schedule) { create(:schedule_rule, :weekend, :all_day, discount_percent: 25, product: product) }

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

  context "when product has duration pricing mode" do
    let(:product) { create(:setup_instrument, pricing_mode: "Duration") }

    describe "#calculate" do
      subject(:costs) { calculator.calculate(start_at, end_at) }

      describe "with no duration rates set" do
        let(:options) { { usage_rate: 120 } }
        let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
        let(:end_at) { start_at + 1.hour }

        it "uses usage_rate as rate" do
          is_expected.to eq(cost: 120, subsidy: 0)
        end
      end

      context "with duration rates" do
        context "rounded to hour time range" do
          context "which is below lowest duration rate minimum duration" do
            let(:options) { { usage_rate: 120 } }
            let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
            let(:end_at) { start_at + 1.hour }

            it "uses usage rate" do
              create(:duration_rate, price_policy: price_policy, min_duration_hours: 3)

              is_expected.to eq(cost: 120, subsidy: 0)
            end
          end

          context "which is above lowest duration rate minimum duration" do
            let(:options) { { usage_rate: 120 } }
            let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
            let(:end_at) { start_at + 4.hour }

            it "uses both usage rate and duration rates" do
              create(:duration_rate, price_policy: price_policy, min_duration_hours: 3)

              # 3 hours @ $120 = $360 Usage rate
              # 1 hour  @ $60  = $60  Duration rate
              is_expected.to eq(cost: 420, subsidy: 0)
            end
          end
        end

        context "not rounded to hour time range" do
          context "which is below lowest duration rate minimum duration" do
            let(:options) { { usage_rate: 120 } }
            let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
            let(:end_at) { start_at + 1.hour + 15.minute }

            it "uses usage rate" do
              create(:duration_rate, price_policy: price_policy, min_duration_hours: 3)

              is_expected.to eq(cost: 120 + 30, subsidy: 0)
            end
          end

          context "which is above lowest duration rate minimum duration" do
            let(:options) { { usage_rate: 120 } }
            let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
            let(:end_at) { start_at + 4.hour + 15.minute }

            it "uses both usage rate and duration rates" do
              create(:duration_rate, price_policy: price_policy, min_duration_hours: 3)

              # 3 hours    @ $120 = $360 Usage rate
              # 1.25 hour  @ $60  = $75  Duration rate
              is_expected.to eq(cost: 435, subsidy: 0)
            end
          end
        end

        context "multiple of them" do
          context "and not rounded to hour time range" do
            context "which is above highest duration rate minimum duration" do
              context "and has subsidy set" do
                let(:options) { { usage_rate: 120, usage_subsidy: 30 } }
                let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
                let(:end_at) { start_at + 5.hour + 15.minute }

                it "uses usage rate, usage subsidy and duration rates" do
                  create(:duration_rate, price_policy: price_policy, min_duration_hours: 1, rate: nil, subsidy: 25)
                  create(:duration_rate, price_policy: price_policy, min_duration_hours: 3, rate: nil, subsidy: 20)
                  create(:duration_rate, price_policy: price_policy, min_duration_hours: 5, rate: nil, subsidy: 15)

                  # Cost
                  # 5.25 hours    @ $120   = $630   Usage rate

                  # Subsidy
                  # 1 hours       @ $30   = $30      Usage subsidy
                  # 2 hours       @ $25   = $50      Duration rate - Minimum duration: 1 hour
                  # 2 hours       @ $20   = $40      Duration rate - Minimum duration: 3 hours
                  # 0.25 hours    @ $15   = $3.75    Duration rate - Minimum duration: 5 hours
                  expect(calculator.calculate(start_at, end_at)[:cost]).to eq(630)
                  expect(calculator.calculate(start_at, end_at)[:subsidy].round(4)).to eq(123.75)
                end
              end

              context "and has rate set" do
                let(:options) { { usage_rate: 120 } }
                let(:start_at) { Time.zone.local(2017, 4, 27, 12, 0) }
                let(:end_at) { start_at + 5.hour + 15.minute }

                it "uses both usage rate and duration rates" do
                  create(:duration_rate, price_policy: price_policy, min_duration_hours: 1, rate: 90)
                  create(:duration_rate, price_policy: price_policy, min_duration_hours: 3)
                  create(:duration_rate, price_policy: price_policy, min_duration_hours: 5, rate: 30)

                  # 1 hours       @ $120 = $120 Usage rate
                  # 2 hours       @ $90  = $180 Duration rate - Minimum duration: 1 hour
                  # 2 hours       @ $60  = $120 Duration rate - Minimum duration: 3 hours
                  # 0.25 hours    @ $30  = $7.5 Duration rate - Minimum duration: 5 hours
                  is_expected.to eq(cost: 427.5, subsidy: 0)
                end
              end
            end
          end
        end
      end
    end
  end
end
