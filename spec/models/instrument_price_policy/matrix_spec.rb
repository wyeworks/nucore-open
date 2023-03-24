# frozen_string_literal: true

require "rails_helper"

#
# Implements the NU provided price policy test matrix
# https://docs.google.com/a/tablexi.com/spreadsheet/ccc?key=0Arnc3pO6pwnFdFlWa2ZKbW40ZzZHUVAzOC1CMERBTXc&usp=sharing
RSpec.describe InstrumentPricePolicy do
  shared_context "Res 3-4, Actual 3-4" do
    let(:reserve) { [15, 0, 16, 0] }
    let(:actual)  { [15, 0, 16, 0] }
  end

  shared_context "Res 3-4, Actual 3-4:15" do
    let(:reserve) { [15, 0, 16, 0] }
    let(:actual)  { [15, 0, 16, 15] }
  end

  shared_context "Res 3-4, Actual 3:15-3:45" do
    let(:reserve) { [15, 0, 16, 0] }
    let(:actual)  { [15, 15, 15, 45] }
  end

  shared_context "Res 3-4, Actual 3:15-4:15" do
    let(:reserve) { [15, 0, 16, 0] }
    let(:actual)  { [15, 15, 16, 15] }
  end

  shared_context "Res 4-6, Actual 4-6" do
    let(:reserve) { [16, 0, 18, 0] }
    let(:actual)  { [16, 0, 18, 0] }
  end

  shared_context "Res 4-6, Actual 4:15-5:45" do
    let(:reserve) { [16, 0, 18, 0] }
    let(:actual)  { [16, 15, 17, 45] }
  end

  shared_context "Res 4-6, Actual 4-6:15" do
    let(:reserve) { [16, 0, 18, 0] }
    let(:actual)  { [16, 0, 18, 15] }
  end

  shared_context "Res 4-6, Actual 4:15-6:15" do
    let(:reserve) { [16, 0, 18, 0] }
    let(:actual)  { [16, 15, 18, 15] }
  end

  shared_context "overage" do
    before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:overage] }
  end

  shared_context "usage" do
    before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:usage] }
  end

  shared_context "reservation" do
    before { policy.charge_for = InstrumentPricePolicy::CHARGE_FOR[:reservation] }
  end

  shared_examples "calculation" do |times|
    include_context times
    describe times do
      describe "overage" do
        include_context "overage"
        it "calculates cost and subsidy" do
          expect(subject[:cost].round 2).to eq overage[:cost]
          expect(subject[:subsidy].round 2).to eq overage[:subsidy]
        end
      end

      describe "usage" do
        include_context "usage"
        it "calculates cost and subsidy" do
          expect(subject[:cost].round 2).to eq usage[:cost]
          expect(subject[:subsidy].round 2).to eq usage[:subsidy]
        end
      end

      describe "reservation" do
        include_context "reservation"
        it "calculates cost and subsidy" do
          expect(subject[:cost].round 2).to eq reservation_cost[:cost]
          expect(subject[:subsidy].round 2).to eq reservation_cost[:subsidy]
        end
      end
    end
  end

  let(:product) { create(:setup_instrument, skip_schedule_rules: true) }
  let!(:rules) do
    create(:schedule_rule, product: product, start_hour: 0, end_hour: 17)
    create(:schedule_rule, product: product, start_hour: 17, end_hour: 21, discount_percent: 20)
  end
  let(:policy) { create :instrument_price_policy, usage_rate: 60, product: product }

  subject(:calculation) { policy.calculate_cost_and_subsidy reservation }

  let(:reservation) do
    now = Time.zone.now
    build_stubbed :reservation,
                  reserve_start_at: now.change(hour: reserve[0], min: reserve[1]),
                  reserve_end_at: now.change(hour: reserve[2], min: reserve[3]),
                  actual_start_at: now.change(hour: actual[0], min: actual[1]),
                  actual_end_at: now.change(hour: actual[2], min: actual[3])
  end

  context "normal price policy with no subsidy" do
    it_behaves_like "calculation", "Res 3-4, Actual 3-4" do
      let(:reservation_cost) { { cost: 60, subsidy: 0 } }
      let(:usage)   { { cost: 60, subsidy: 0 } }
      let(:overage) { { cost: 60, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3:15-3:45" do
      let(:reservation_cost) { { cost: 60, subsidy: 0 } }
      let(:usage)   { { cost: 30, subsidy: 0 } }
      let(:overage) { { cost: 60, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3-4:15" do
      let(:reservation_cost) { { cost: 60, subsidy: 0 } }
      let(:usage)   { { cost: 75, subsidy: 0 } }
      let(:overage) { { cost: 75, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3:15-4:15" do
      let(:reservation_cost) { { cost: 60, subsidy: 0 } }
      let(:usage)   { { cost: 60, subsidy: 0 } }
      let(:overage) { { cost: 75, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4-6" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 108, subsidy: 0 } }
      let(:overage) { { cost: 108, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4-6:15" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 120, subsidy: 0 } }
      let(:overage) { { cost: 120, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4:15-5:45" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 81, subsidy: 0 } }
      let(:overage) { { cost: 108, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4:15-6:15" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 105, subsidy: 0 } }
      let(:overage) { { cost: 120, subsidy: 0 } }
    end

  end

  context "with a subsidized price" do
    before { policy.usage_subsidy = 20 }

    it_behaves_like "calculation", "Res 3-4, Actual 3-4" do
      let(:reservation_cost) { { cost: 60, subsidy: 20 } }
      let(:usage)   { { cost: 60, subsidy: 20 } }
      let(:overage) { { cost: 60, subsidy: 20 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3:15-3:45" do
      let(:reservation_cost) { { cost: 60, subsidy: 20 } }
      let(:usage)   { { cost: 30, subsidy: 10 } }
      let(:overage) { { cost: 60, subsidy: 20 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3-4:15" do
      let(:reservation_cost) { { cost: 60, subsidy: 20 } }
      let(:usage)   { { cost: 75, subsidy: 25 } }
      let(:overage) { { cost: 75, subsidy: 25 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3:15-4:15" do
      let(:reservation_cost) { { cost: 60, subsidy: 20 } }
      let(:usage)   { { cost: 60, subsidy: 20 } }
      let(:overage) { { cost: 75, subsidy: 25 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4-6" do
      let(:reservation_cost) { { cost: 108, subsidy: 36 } }
      let(:usage)   { { cost: 108, subsidy: 36 } }
      let(:overage) { { cost: 108, subsidy: 36 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4-6:15" do
      let(:reservation_cost) { { cost: 108, subsidy: 36 } }
      let(:usage)   { { cost: 120, subsidy: 40 } }
      let(:overage) { { cost: 120, subsidy: 40 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4:15-5:45" do
      let(:reservation_cost) { { cost: 108, subsidy: 36 } }
      let(:usage)   { { cost: 81, subsidy: 27 } }
      let(:overage) { { cost: 108, subsidy: 36 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4:15-6:15" do
      let(:reservation_cost) { { cost: 108, subsidy: 36 } }
      let(:usage)   { { cost: 105, subsidy: 35 } }
      let(:overage) { { cost: 120, subsidy: 40 } }
    end

  end

  context "with a minimum cost" do
    before { policy.minimum_cost = 100 }

    it_behaves_like "calculation", "Res 3-4, Actual 3-4" do
      let(:reservation_cost) { { cost: 100, subsidy: 0 } }
      let(:usage)   { { cost: 100, subsidy: 0 } }
      let(:overage) { { cost: 100, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3:15-3:45" do
      let(:reservation_cost) { { cost: 100, subsidy: 0 } }
      let(:usage)   { { cost: 100, subsidy: 0 } }
      let(:overage) { { cost: 100, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3-4:15" do
      let(:reservation_cost) { { cost: 100, subsidy: 0 } }
      let(:usage)   { { cost: 100, subsidy: 0 } }
      let(:overage) { { cost: 100, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 3-4, Actual 3:15-4:15" do
      let(:reservation_cost) { { cost: 100, subsidy: 0 } }
      let(:usage)   { { cost: 100, subsidy: 0 } }
      let(:overage) { { cost: 100, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4-6" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 108, subsidy: 0 } }
      let(:overage) { { cost: 108, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4-6:15" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 120, subsidy: 0 } }
      let(:overage) { { cost: 120, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4:15-5:45" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 100, subsidy: 0 } }
      let(:overage) { { cost: 108, subsidy: 0 } }
    end

    it_behaves_like "calculation", "Res 4-6, Actual 4:15-6:15" do
      let(:reservation_cost) { { cost: 108, subsidy: 0 } }
      let(:usage)   { { cost: 105, subsidy: 0 } }
      let(:overage) { { cost: 120, subsidy: 0 } }
    end

  end
end
