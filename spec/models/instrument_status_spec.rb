require "rails_helper"

RSpec.describe InstrumentStatus do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument, facility: facility) }

  describe ".set_status_for" do
    it "creates a new status if one does not exist" do
      expect do
        described_class.set_status_for(instrument, is_on: true)
      end.to change(described_class, :count).by(1)
    end

    it "updates an existing status instead of creating a new one" do
      described_class.set_status_for(instrument, is_on: true)

      expect do
        described_class.set_status_for(instrument, is_on: false)
      end.not_to change(described_class, :count)

      expect(instrument.current_instrument_status).not_to be_on
    end

    it "updates the updated_at timestamp" do
      status = described_class.set_status_for(instrument, is_on: true)
      original_updated_at = status.updated_at

      travel_to 1.minute.from_now do
        status = described_class.set_status_for(instrument, is_on: false)
        expect(status.updated_at).to be > original_updated_at
      end
    end

    it "returns the instrument status" do
      status = described_class.set_status_for(instrument, is_on: true)

      expect(status).to be_a(described_class)
      expect(status).to be_persisted
      expect(status.instrument).to eq(instrument)
      expect(status).to be_on
    end
  end

  describe "#as_json" do
    let(:status) { described_class.set_status_for(instrument, is_on: true) }

    it "includes expected fields" do
      json = status.as_json

      expect(json[:instrument_status]).to include(
        name: instrument.name,
        instrument_id: instrument.id,
        schedule_id: instrument.schedule_id,
        is_on: true,
        error_message: nil
      )
    end

    it "includes updated_at in ISO8601 format" do
      json = status.as_json

      expect(json[:instrument_status][:updated_at]).to eq(status.updated_at.iso8601)
    end

    it "includes error_message when set" do
      status.error_message = "Connection failed"
      json = status.as_json

      expect(json[:instrument_status][:error_message]).to eq("Connection failed")
    end
  end
end
