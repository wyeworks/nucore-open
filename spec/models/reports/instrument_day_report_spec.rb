# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::InstrumentDayReport do
  subject(:report) { described_class.new(reservations) }
  let(:product) { build_stubbed(:product, name: "Test 1") }
  let(:product2) { build_stubbed(:product, name: "Test 2") }
  let(:reports) do
    {
      reserved_hours: ->(res) { Reports::InstrumentDayReport::ReservedHours.new(res) },
      actual_hours: ->(res) { Reports::InstrumentDayReport::ActualHours.new(res) },
    }
  end

  before :each do
    report.build_report(&reports.fetch(report_on))
  end

  let(:tuesday) { Time.zone.local(2017, 7, 11, 12, 0) }
  let(:friday) { Time.zone.local(2017, 7, 14, 12, 0) }

  context "with actual reservations" do
    let(:product1_reservations) { build_stubbed_list(:reservation, 3, reserve_start_at: tuesday, duration_mins: 35, actual_start_at: tuesday, actual_duration_mins: 60, product:) }
    let(:product2_reservations) { build_stubbed_list(:reservation, 2, reserve_start_at: friday, duration_mins: 25, actual_start_at: friday, actual_duration_mins: 15, product: product2) }
    let(:reservations) { product1_reservations + product2_reservations }

    describe "reserved hours" do
      let(:report_on) { :reserved_hours }

      it "has the correct totals" do
        totals = report.totals
        expect(totals).to eq([0.0, 0.0, 1.8, 0.0, 0.0, 0.8, 0.0])
      end

      it "has the correct rows" do
        rows = report.rows
        expect(rows[0]).to eq([product.name, 0.0, 0.0, 1.8, 0.0, 0.0, 0.0, 0.0])
        expect(rows[1]).to eq([product2.name, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.0])
      end
    end

    describe "actual hours" do
      let(:report_on) { :actual_hours }

      it "has the correct totals" do
        totals = report.totals
        expect(totals).to eq([0.0, 0.0, 3.0, 0.0, 0.0, 0.5, 0.0])
      end

      it "has the correct rows" do
        rows = report.rows
        expect(rows[0]).to eq([product.name, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0])
        expect(rows[1]).to eq([product2.name, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0])
      end
    end
  end

  context "with zero length actuals" do
    let(:product1_reservations) { build_stubbed_list(:reservation, 3, duration_mins: 35, actual_start_at: tuesday, actual_duration_mins: 0, product:) }
    let(:product2_reservations) { build_stubbed_list(:reservation, 2, duration_mins: 35, actual_start_at: friday, actual_duration_mins: 0, product: product2) }
    let(:reservations) { product1_reservations + product2_reservations }
    let(:report_on) { :actual_hours }

    it "has the correct rows" do
      rows = report.rows
      expect(rows[0]).to eq([product.name, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
      expect(rows[1]).to eq([product2.name, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    end
  end

  describe "with a problem reservation" do
    let(:reservations) do
      build_stubbed_list(:reservation, 3, reserve_start_at: tuesday, duration_mins: 30,
                                          actual_start_at: tuesday, actual_end_at: nil, product:)
    end

    describe "reserved_hours" do
      let(:report_on) { :reserved_hours }
      it "has the correct row" do
        rows = report.rows
        expect(rows[0]).to eq([product.name, 0.0, 0.0, 1.5, 0.0, 0.0, 0.0, 0.0])
      end
    end

    describe "actual_hours" do
      let(:report_on) { :actual_hours }
      it "has the correct row" do
        rows = report.rows
        expect(rows[0]).to eq([product.name, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
      end
    end
  end
end
