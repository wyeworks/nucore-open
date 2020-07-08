# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationInstrumentSwitcher do
  let(:instrument) { FactoryBot.create(:setup_instrument, relay: build(:relay_syna)) }
  let(:reservation) { FactoryBot.create(:purchased_reservation, product: instrument) }
  let(:action) { described_class.new(reservation) }

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
  end
end
