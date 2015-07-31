require 'spec_helper'

describe Relay do
  it { is_expected.to allow_mass_assignment_of :auto_logout }
  it { is_expected.to allow_mass_assignment_of :auto_logout_minutes }
  it { is_expected.to allow_mass_assignment_of :instrument_id }
  it { is_expected.to allow_mass_assignment_of :type }


  context 'with relay' do

    before :each do
      @facility         = create(:facility)
      @facility_account = @facility.facility_accounts.create(attributes_for(:facility_account))
      @instrument       = create(:instrument,
                                                :facility => @facility,
                                                :facility_account => @facility_account,
                                                :no_relay => true)

      @relay            = create(:relay_syna, :instrument => @instrument)
    end

    describe 'validating uniqueness' do
      it 'does not allow two different instruments to have the same IP/port' do
        instrument2 = create :instrument,
                              facility: @facility,
                              facility_account: @facility_account,
                              no_relay: true
        relay2 = build :relay_syna, instrument: instrument2, port: @relay.port
        expect(relay2).to_not be_valid
      end

      it 'allows two shared schedule instruments to include the same IP/port' do
        instrument2 = create :instrument,
                              facility: @facility,
                              facility_account: @facility_account,
                              no_relay: true,
                              schedule: @instrument.schedule
        relay2 = build :relay_syna, instrument: instrument2, port: @relay.port
        expect(relay2).to be_valid
      end

    end

    it 'should alias host to ip' do
      expect(@relay.host).to eq(@relay.ip)
    end

    context 'dummy relay' do

      before :each do
        @relay.destroy
        expect(@relay).to be_destroyed
        @relay=RelayDummy.create!(:instrument_id => @instrument.id)
      end


      it 'should turn on the relay' do
        @relay.activate
        expect(@relay.get_status).to eq(true)
      end


      it 'should turn off the relay' do
        @relay.deactivate
        expect(@relay.get_status).to eq(false)
      end

    end

  end

end
