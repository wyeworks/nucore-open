# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentStatusFetcher do
  let(:facility) { create(:setup_facility) }
  let!(:relay) { create(:relay_syna, instrument: instrument_with_relay) }
  let!(:instrument_with_relay) { create(:instrument, no_relay: true, facility: facility) }
  let!(:instrument_with_dummy_relay) { create(:instrument, facility: facility) }
  let!(:reservation_only_instrument) { create(:instrument, no_relay: true, facility: facility) }
  subject(:fetcher) { described_class.new(facility) }

  before do
    allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(true)
  end

  describe "#statuses" do
    let(:statuses) { fetcher.statuses }

    it "includes the instrument with real relays" do
      expect(statuses.map(&:instrument)).to include(instrument_with_relay)
    end

    it "excludes instruments without relays" do
      expect(statuses.map(&:instrument)).not_to include(reservation_only_instrument)
    end

    it "excludes instruments with timers" do
      expect(statuses.map(&:instrument)).not_to include(instrument_with_dummy_relay)
    end

    context "when there is a stored status" do
      before do
        InstrumentStatus.set_status_for(instrument_with_relay, is_on: true)
      end

      it "returns the stored status without polling the relay" do
        expect_any_instance_of(RelaySynaccessRevA).not_to receive(:query_status)
        expect(statuses.find { |status| status.instrument == instrument_with_relay }).to be_on
      end
    end

    context "when there is no stored status" do
      it "returns a status with nil is_on" do
        status = statuses.find { |s| s.instrument == instrument_with_relay }
        expect(status.is_on).to be_nil
      end
    end
  end

  describe "#statuses with refresh" do
    before do
      allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(true)
    end

    it "polls the relay and saves the status" do
      expect_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(true)

      statuses = fetcher.statuses(refresh: true)
      status = statuses.find { |s| s.instrument == instrument_with_relay }

      expect(status).to be_on
      expect(status).to be_persisted
      expect(status.updated_at).to be_present
    end

    it "updates an existing status instead of creating a new one" do
      InstrumentStatus.set_status_for(instrument_with_relay, is_on: false)
      expect(InstrumentStatus.where(instrument: instrument_with_relay).count).to eq(1)

      fetcher.statuses(refresh: true)

      expect(InstrumentStatus.where(instrument: instrument_with_relay).count).to eq(1)
      expect(instrument_with_relay.reload.instrument_status).to be_on
    end

    it "handles errors gracefully" do
      allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_raise(StandardError.new("Connection failed"))

      statuses = fetcher.statuses(refresh: true)
      status = statuses.find { |s| s.instrument == instrument_with_relay }

      expect(status.error_message).to eq("Connection failed")
    end

    it "excludes instruments without networked relays" do
      statuses = fetcher.statuses(refresh: true)
      expect(statuses.map(&:instrument)).not_to include(reservation_only_instrument)
    end

    it "excludes instruments with dummy relays" do
      statuses = fetcher.statuses(refresh: true)
      expect(statuses.map(&:instrument)).not_to include(instrument_with_dummy_relay)
    end
  end

  describe "when relays are disabled" do
    before do
      allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(false)
    end

    it "returns on status without polling" do
      expect_any_instance_of(RelaySynaccessRevA).not_to receive(:query_status)
      expect(fetcher.statuses.first).to be_on
    end

    it "statuses with refresh returns on status without polling" do
      expect_any_instance_of(RelaySynaccessRevA).not_to receive(:query_status)
      statuses = fetcher.statuses(refresh: true)
      status = statuses.find { |s| s.instrument == instrument_with_relay }
      expect(status).to be_on
    end

    it "statuses with refresh saves status with updated_at" do
      statuses = fetcher.statuses(refresh: true)
      status = statuses.find { |s| s.instrument == instrument_with_relay }
      expect(status).to be_persisted
      expect(status.updated_at).to be_present
    end

    it "statuses returns status with updated_at after refresh" do
      # First refresh to create a status
      fetcher.statuses(refresh: true)

      status = fetcher.statuses.find { |s| s.instrument == instrument_with_relay }
      expect(status.updated_at).to be_present
    end
  end
end
