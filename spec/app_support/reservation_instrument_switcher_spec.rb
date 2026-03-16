# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationInstrumentSwitcher do
  let(:instrument) { FactoryBot.create(:setup_instrument, relay: build(:relay_syna)) }
  let(:reservation) { FactoryBot.create(:purchased_reservation, product: instrument) }
  let(:action) { described_class.new(reservation) }

  let(:relay_connection) { double("RelayConnection") }

  before do
    allow_any_instance_of(RelaySynaccessRevA).to receive(:relay_connection).and_return(relay_connection)
    allow(relay_connection).to receive(:toggle) { |_outlet, status| status }
    allow(relay_connection).to receive(:status).and_return(true)

    allow(SettingsHelper).to receive(:relays_enabled_for_reservation?) { true }
  end

  describe "#switch_on!" do
    def do_action
      action.switch_on!
    end

    before do
      allow(reservation).to receive(:can_switch_instrument_on?).and_return(true)
    end

    context "no other reservations" do
      it "starts the reservation" do
        expect { do_action }.to change { reservation.reload.actual_start_at }.from(nil)
      end

      it "updates InstrumentStatus to on" do
        do_action
        status = InstrumentStatus.find_by(instrument_id: instrument.id)
        expect(status.is_on).to be true
      end
    end

    context "with a long running reservation" do
      let!(:running_reservation) { FactoryBot.create(:purchased_reservation, :long_running, product: instrument) }

      it "moves the running reservation to problem status" do
        expect { do_action }.to change { running_reservation.order_detail.reload.problem }.from(false).to(true)
      end
    end

    context "with a problem reservation that got canceled" do
      let!(:running_reservation) { FactoryBot.create(:purchased_reservation, :long_running, product: instrument) }
      before { running_reservation.order_detail.update_order_status! running_reservation.user, OrderStatus.canceled, admin: true }

      it "does not do anything to the canceled reservation" do
        expect { do_action }.not_to change { running_reservation.reload }
      end
    end

    context "with a problem reservation that got reconciled" do
      let!(:running_reservation) { FactoryBot.create(:purchased_reservation, :long_running, product: instrument) }
      before do
        running_reservation.order_detail.update_order_status! running_reservation.user, OrderStatus.complete, admin: true
        running_reservation.order_detail.update_order_status! running_reservation.user, OrderStatus.reconciled, admin: true
      end

      it "does not do anything to the canceled reservation" do
        expect { do_action }.not_to change { running_reservation.reload }
      end
    end

    context "when cannot switch instrument" do
      before do
        allow_any_instance_of(Reservation).to receive(:can_switch_instrument_on?) { false }
      end

      it "raises error" do
        expect { do_action }.to raise_error(NUCore::Error, /cannot switch instrument/i)
      end
    end
  end

  describe "#switch_off!" do
    def do_action
      action.switch_off!
    end

    before do
      allow(reservation).to receive(:can_switch_instrument_off?).and_return(true)
      # Start the reservation so it can be ended
      reservation.update!(actual_start_at: 30.minutes.ago)
    end

    it "ends the reservation" do
      expect { do_action }.to change { reservation.reload.actual_end_at }.from(nil)
    end

    it "updates InstrumentStatus to off" do
      # Set initial status to ON
      InstrumentStatus.create!(instrument:, is_on: true)

      do_action
      expect(InstrumentStatus.find_by(instrument_id: instrument.id).is_on).to be false
    end

    context "when relays are enabled" do
      before do
        allow(SettingsHelper).to receive(:relays_enabled_for_reservation?).and_return(true)
      end

      it "does not call get_status on the relay" do
        expect(instrument.relay).not_to receive(:get_status)
        do_action
      end

      it "updates InstrumentStatus to off" do
        InstrumentStatus.create!(instrument:, is_on: true)

        do_action
        expect(InstrumentStatus.find_by(instrument_id: instrument.id).is_on).to be false
      end

      context "when the relay deactivation raises an error" do
        before do
          allow(relay_connection).to receive(:toggle).and_raise(NetBooter::Error, "Connection failed")
        end

        it "raises and does not update InstrumentStatus" do
          InstrumentStatus.create!(instrument:, is_on: true)

          expect { do_action }.to raise_error(NetBooter::Error)
          expect(InstrumentStatus.find_by(instrument_id: instrument.id).is_on).to be true
        end
      end
    end
  end
end
