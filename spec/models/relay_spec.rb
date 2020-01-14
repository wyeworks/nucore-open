# frozen_string_literal: true

require "rails_helper"

RSpec.describe Relay do

  context "with relay" do

    before :each do
      @facility = create(:setup_facility)
      @facility_account = @facility.facility_accounts.first
      @instrument = create(:instrument,
                           facility: @facility,
                           facility_account: @facility_account,
                           no_relay: true)

      @relay = create(:relay_syna, instrument: @instrument)
    end

    describe "validating uniqueness" do
      it "does not allow two different instruments to have the same IP/outlet" do
        instrument2 = create :instrument,
                             facility: @facility,
                             facility_account: @facility_account,
                             no_relay: true
        relay2 = build :relay_syna, instrument: instrument2, outlet: @relay.outlet
        expect(relay2).to_not be_valid
      end

      it "allows two shared schedule instruments to include the same IP/outlet" do
        instrument2 = create :instrument,
                             facility: @facility,
                             facility_account: @facility_account,
                             no_relay: true,
                             schedule: @instrument.schedule
        relay2 = build :relay_syna, instrument: instrument2, outlet: @relay.outlet
        expect(relay2).to be_valid
      end

    end

    it "should alias host to ip" do
      expect(@relay.host).to eq(@relay.ip)
    end

    context "dummy relay" do

      before :each do
        @relay.destroy
        expect(@relay).to be_destroyed
        @relay = RelayDummy.create!(instrument_id: @instrument.id)
      end

      it "should turn on the relay" do
        @relay.activate
        expect(@relay.get_status).to eq(true)
      end

      it "should turn off the relay" do
        @relay.deactivate
        expect(@relay.get_status).to eq(false)
      end

    end

  end

end
