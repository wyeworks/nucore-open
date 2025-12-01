require "rails_helper"

RSpec.describe InstrumentStatusFetcher do
  let(:facility) { create(:setup_facility) }
  let!(:relay) { create(:relay_syna, instrument: instrument_with_relay) }
  let!(:instrument_with_relay) { create(:instrument, no_relay: true, facility: facility) }
  let!(:instrument_with_dummy_relay) { create(:instrument, facility: facility) }
  let!(:reservation_only_instrument) { create(:instrument, no_relay: true, facility: facility) }
  subject(:fetcher) { described_class.new(facility) }
  let(:statuses) { fetcher.statuses }

  before do
    allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(true)
  end

  describe "#statuses" do
    it "includes the instrument with real relays" do
      expect(statuses.map(&:instrument)).to include(instrument_with_relay)
    end

    it "excludes instruments without relays" do
      expect(statuses.map(&:instrument)).not_to include(reservation_only_instrument)
    end

    it "excludes instruments with timers" do
      expect(statuses.map(&:instrument)).not_to include(instrument_with_dummy_relay)
    end

    context "when there is a cached status" do
      before do
        InstrumentStatus.set_status_for(instrument_with_relay, is_on: true)
      end

      it "returns the cached status without polling the relay" do
        expect_any_instance_of(RelaySynaccessRevA).not_to receive(:query_status)
        expect(statuses.find { |status| status.instrument == instrument_with_relay }).to be_on
      end
    end

    context "when there is no cached status" do
      it "returns a status with nil is_on" do
        status = statuses.find { |s| s.instrument == instrument_with_relay }
        expect(status.is_on).to be_nil
      end
    end
  end

  describe ".refresh_status" do
    before do
      allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(true)
    end

    it "polls the relay and saves the status" do
      expect_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(true)

      status = described_class.refresh_status(instrument_with_relay)

      expect(status).to be_on
      expect(status).to be_persisted
      expect(status.updated_at).to be_present
    end

    it "updates an existing status instead of creating a new one" do
      InstrumentStatus.set_status_for(instrument_with_relay, is_on: false)
      expect(InstrumentStatus.where(instrument: instrument_with_relay).count).to eq(1)

      described_class.refresh_status(instrument_with_relay)

      expect(InstrumentStatus.where(instrument: instrument_with_relay).count).to eq(1)
      expect(instrument_with_relay.reload.instrument_status).to be_on
    end

    it "handles errors gracefully" do
      allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_raise(StandardError.new("Connection failed"))

      status = described_class.refresh_status(instrument_with_relay)

      expect(status.error_message).to eq("Connection failed")
    end

    it "returns nil for instruments without networked relays" do
      expect(described_class.refresh_status(reservation_only_instrument)).to be_nil
    end

    it "returns nil for instruments with dummy relays" do
      expect(described_class.refresh_status(instrument_with_dummy_relay)).to be_nil
    end
  end

  describe "when relays are disabled" do
    before do
      allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(false)
    end

    it "returns on status without polling" do
      expect_any_instance_of(RelaySynaccessRevA).not_to receive(:query_status)
      expect(statuses.first).to be_on
    end

    it "refresh_status returns on status without polling" do
      expect_any_instance_of(RelaySynaccessRevA).not_to receive(:query_status)
      status = described_class.refresh_status(instrument_with_relay)
      expect(status).to be_on
    end

    it "refresh_status saves status with updated_at" do
      status = described_class.refresh_status(instrument_with_relay)
      expect(status).to be_persisted
      expect(status.updated_at).to be_present
    end

    it "statuses returns status with updated_at" do
      # First refresh to create a status
      described_class.refresh_status(instrument_with_relay)

      status = statuses.find { |s| s.instrument == instrument_with_relay }
      expect(status.updated_at).to be_present
    end
  end
end
