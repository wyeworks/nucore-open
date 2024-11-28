# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::AdminReports::RelayCsvReport do
  subject(:report) { UmassCorum::AdminReports::RelayCsvReport.new }

  describe "#to_csv" do
    context "with no relays" do
      it "generates a header", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(1)
        expect(lines[0]).to eq("Facility Name,Instrument Name,Active/Inactive,Relay Type,Relay IP Address,Relay IP Port,Outlet Number,Auto Logout Minutes\n")
      end

      it "sets the filename based on the passed in product name" do
        expect(report.filename).to eq("instrument_relay_data.csv")
      end
    end

    context "with relays" do
      let!(:relay_1) { create(:relay, instrument: create(:setup_instrument)) }
      let!(:relay_2) { create(:relay, instrument: create(:setup_instrument)) }
      let!(:relay_3) { create(:relay, instrument: create(:setup_instrument)) }

      it "generates a header line and 3 data lines", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(4)
        expect(lines[1]).to eq("#{relay_1.instrument.facility},#{relay_1.instrument},Active,RelaySynaccessRevA,192.168.1.1,,#{relay_1.outlet},None\n")
        expect(lines[2]).to eq("#{relay_2.instrument.facility},#{relay_2.instrument},Active,RelaySynaccessRevA,192.168.1.1,,#{relay_2.outlet},None\n")
        expect(lines[3]).to eq("#{relay_3.instrument.facility},#{relay_3.instrument},Active,RelaySynaccessRevA,192.168.1.1,,#{relay_3.outlet},None\n")
      end
    end
  end
end
