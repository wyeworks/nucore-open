require "rails_helper"

RSpec.describe InstrumentStatusFetcher do
  let(:facility) { create(:setup_facility) }
  let!(:relay) { create(:relay_syna, instrument: instrument_with_relay) }
  let!(:instrument_with_relay) { create(:instrument, no_relay: true, facility: facility) }
  let!(:instrument_with_dummy_relay) { create(:instrument, facility: facility) }
  let!(:reservation_only_instrument) { create(:instrument, no_relay: true, facility: facility) }
  subject(:fetcher) { described_class.new(facility) }
  let(:statuses) { fetcher.statuses }

  # Otherwise
  before do
    allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(true)
    allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(true)
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

    it "has the status" do
      expect(statuses.find { |status| status.instrument == instrument_with_relay }).to be_on
    end

    it "has a false status" do
      allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(false)
      expect(statuses.find { |status| status.instrument == instrument_with_relay }).not_to be_on
    end

    it "can have an error" do
      allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_raise(StandardError.new("Error!"))
      expect(statuses.first.error_message).to eq("Error!")
    end
  end

  describe "caching" do
    describe "with a second identical relay" do
      let!(:relay2) {create(:relay_syna, relay.attributes.except("id").merge(instrument: instrument_with_relay2)) }
      let(:instrument_with_relay2) { create(:instrument, no_relay: true, facility: facility, schedule: instrument_with_relay.schedule) }

      it "only fetches once" do
        allow_any_instance_of(Instrument).to receive(:relay).and_return relay
        expect(relay).to receive(:query_status).once
        statuses
      end

      it "returns two instrument_ids" do
        expect(statuses.map(&:instrument)).to contain_exactly(instrument_with_relay, instrument_with_relay2)
      end
    end
  end
end
