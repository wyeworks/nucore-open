# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::InstrumentUtilizationReport do
  subject(:report) { described_class.new(reservations) }
  let(:product) { build_stubbed(:product, name: "Test 1") }
  let(:product2) { build_stubbed(:product, name: "Test 2") }

  before :each do
    report.build_report
  end

  context "with actual reservations" do
    let(:product1_reservations) { build_stubbed_list(:reservation, 3, duration_mins: 35, actual_duration_mins: 15, product:) }
    let(:product2_reservations) { build_stubbed_list(:reservation, 2, duration_mins: 25, actual_duration_mins: 5, product: product2) }
    let(:reservations) { product1_reservations + product2_reservations }

    it "has the correct totals" do
      totals = report.totals
      expect(totals).to eq(["5", 2.6, "100.0%", 0.9, "100.0%"])
    end

    it "has the correct rows" do
      rows = report.rows
      expect(rows[0]).to eq([product.name, "3", 1.8, "67.7%", 0.8, "81.8%"])
      expect(rows[1]).to eq([product2.name, "2", 0.8, "32.3%", 0.2, "18.2%"])
    end
  end

  context "with zero length actuals" do
    let(:product1_reservations) { build_stubbed_list(:reservation, 3, duration_mins: 35, actual_duration_mins: 0, product:) }
    let(:product2_reservations) { build_stubbed_list(:reservation, 2, duration_mins: 35, actual_duration_mins: 0, product: product2) }
    let(:reservations) { product1_reservations + product2_reservations }

    it "has the correct totals" do
      totals = report.totals
      expect(totals).to eq(["5", 2.9, "100.0%", 0, "0.0%"])
    end

    it "has the correct rows" do
      rows = report.rows
      expect(rows[0]).to eq([product.name, "3", 1.8, "60.0%", 0, "0.0%"])
      expect(rows[1]).to eq([product2.name, "2", 1.2, "40.0%", 0, "0.0%"])
    end
  end

  describe "with a problem reservation" do
    let(:reservations) do
      build_stubbed_list(:reservation, 3, duration_mins: 30,
                                          actual_start_at: 1.hour.ago, actual_end_at: nil, product:)
    end

    it "has the correct row" do
      expect(report.rows[0]).to eq([product.name, "3", 1.5, "100.0%", 0, "0.0%"])
    end
  end
end
