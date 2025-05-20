# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::AdminReports::FacilityRatesCsvReport do
  let(:facility) { create(:setup_facility, name: "Animal Imaging", abbreviation: "ANIMG") }
  let(:base_price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }
  let(:cancer_center_price_group) { create(:price_group, :cancer_center) }

  subject(:report) { UmassCorum::AdminReports::FacilityRatesCsvReport.new }

  describe "#to_csv" do
    context "with no rates" do
      it "generates a header", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(1)
        expect(lines[0]).to eq("Facility Name,Instrument Name,Active/Inactive,Note,Start Date,Expire Date,Billing Mode,Pricing Mode,Unit Cost,Unit Subsidy,Usage Rate,Minimum Cost,Reservation Cost,Usage Subsidy,Duration Step 1,Duration Rate 1,Duration Subsidy 1,Duration Step 2,Duration Rate 2,Duration Subsidy 2,Duration Step 3,Duration Rate 3,Duration Subsidy 3,Daily Usage Rate,Daily Usage Subsidy Rate,Charge For,Full Price Cancellation,Price Group,Internal/External,Custom Price Group Facility,Created By,Created,Updated,Deleted\n")
      end

      it "sets the filename based on the passed in report name" do
        expect(report.filename).to eq("facility_rates_data.csv")
      end
    end

    context "with schedule rule rates" do
      let(:product) { create(:instrument, facility:, name: "Instrument One", pricing_mode: Instrument::Pricing::SCHEDULE_RULE) }
      let!(:base_price_policy) do
        create(:instrument_price_policy, price_group: base_price_group, product: product, usage_rate: 60)
      end
      let!(:external_price_policy) do
        create(:instrument_price_policy, price_group: external_price_group, product: product, usage_rate: 200)
      end
      let!(:cancer_center_price_policy) do
        create(:instrument_price_policy, price_group: cancer_center_price_group, product: product, usage_rate: 180, usage_subsidy: 60)
      end

      it "generates a header line and some data lines", :aggregate_failures do
        lines = report.to_csv.encode('UTF-8').lines
        expect(lines.count).to eq(4)
        expect(lines[1]).to start_with("Animal Imaging (ANIMG),Instrument One,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Schedule Rule,,,$1.00,$1.00,,$0.00,,,,,,,,,,,,Reservation,,#{base_price_group},Internal,,,")
        expect(lines[2]).to start_with("Animal Imaging (ANIMG),Instrument One,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Schedule Rule,,,$3.33,$1.00,,$0.00,,,,,,,,,,,,Reservation,,#{external_price_group},External,,,")
        expect(lines[3]).to start_with("Animal Imaging (ANIMG),Instrument One,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Schedule Rule,,,$3.00,$1.00,,$1.00,,,,,,,,,,,,Reservation,,#{cancer_center_price_group},Internal,,,")
      end
    end

    context "with duration mode rates" do
      let(:product) { create(:instrument, facility:, name: "Instrument Duration Mode", pricing_mode: Instrument::Pricing::DURATION) }
      let(:base_price_policy) do
        create(:instrument_price_policy, price_group: base_price_group, product: product, usage_rate: 100)
      end
      let(:external_price_policy) do
        create(:instrument_price_policy, price_group: external_price_group, product: product, usage_rate: 200)
      end
      let(:cancer_center_price_policy) do
        create(:instrument_price_policy, price_group: cancer_center_price_group, product: product, usage_rate: 100, usage_subsidy: 10)
      end

      # create duration_rates
      let!(:base_duration_rate) do
        create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 1, rate: 90, subsidy: 0)
        create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 2, rate: 80, subsidy: 0)
        create(:duration_rate, price_policy: base_price_policy, min_duration_hours: 3, rate: 50, subsidy: 0)
      end
      let!(:external_duration_rate) do
        create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 1, rate: 180, subsidy: 0)
        create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 2, rate: 160, subsidy: 0)
        create(:duration_rate, price_policy: external_price_policy, min_duration_hours: 3, rate: 100, subsidy: 0)
      end
      let!(:cancer_center_duration_rate) do
        create(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 1, rate: 90, subsidy: 10)
        create(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 2, rate: 80, subsidy: 12)
        create(:duration_rate, price_policy: cancer_center_price_policy, min_duration_hours: 3, rate: 50, subsidy: 14)
      end
      it "generates a header line and some duration mode data lines", :aggregate_failures do
        lines = report.to_csv.encode('UTF-8').lines
        expect(lines.count).to eq(4)
        expect(lines[1]).to start_with("Animal Imaging (ANIMG),Instrument Duration Mode,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Duration,,,$1.67,$1.00,,$0.00,1,$1.50,$0.00,2,$1.33,$0.00,3,$0.83,$0.00,,,Reservation,,#{base_price_group},Internal,,,")
        expect(lines[2]).to start_with("Animal Imaging (ANIMG),Instrument Duration Mode,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Duration,,,$3.33,$1.00,,$0.00,1,$3.00,$0.00,2,$2.67,$0.00,3,$1.67,$0.00,,,Reservation,,#{external_price_group},External,,,")
        expect(lines[3]).to start_with("Animal Imaging (ANIMG),Instrument Duration Mode,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Duration,,,$1.67,$1.00,,$0.17,1,$1.50,$0.17,2,$1.33,$0.20,3,$0.83,$0.23,,,Reservation,,#{cancer_center_price_group},Internal,,,")
      end
    end

    context "with daily mode rates" do
      let(:product) { create(:instrument, facility:, name: "Instrument Daily Mode", pricing_mode: Instrument::Pricing::SCHEDULE_DAILY) }
      let!(:base_price_policy) do
        create(:instrument_price_policy, price_group: base_price_group, product: product, usage_rate: nil, usage_rate_daily: 125)
      end
      let!(:external_price_policy) do
        create(:instrument_price_policy, price_group: external_price_group, product: product, usage_rate: nil, usage_rate_daily: 250)
      end
      let!(:cancer_center_price_policy) do
        create(:instrument_price_policy, price_group: cancer_center_price_group, product: product, usage_rate: nil, usage_rate_daily: 125, usage_subsidy: 25)
      end

      it "generates a header line and some daily rate mode data lines", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(4)
        expect(lines[1]).to start_with("Animal Imaging (ANIMG),Instrument Daily Mode,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Schedule Rule (Daily Booking only),,,,$1.00,,,,,,,,,,,,$125.00,$0.00,Reservation,,#{base_price_group},Internal,,,")
        expect(lines[2]).to start_with("Animal Imaging (ANIMG),Instrument Daily Mode,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Schedule Rule (Daily Booking only),,,,$1.00,,,,,,,,,,,,$250.00,$0.00,Reservation,,#{external_price_group},External,,,")
        expect(lines[3]).to start_with("Animal Imaging (ANIMG),Instrument Daily Mode,Active,This is note,07/11/2025 12:00 AM,06/30/2026 11:59 PM,Default,Schedule Rule (Daily Booking only),,,,$1.00,,,,,,,,,,,,$125.00,$0.00,Reservation,,#{cancer_center_price_group},Internal,,,")
      end
    end
  end
end
