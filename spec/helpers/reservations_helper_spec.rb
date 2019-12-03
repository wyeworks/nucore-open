# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReservationsHelper do
  describe "#end_time_editing_disabled?" do
    context "when the reservation is not persisted" do
      subject(:reservation) { Reservation.new }

      it { expect(end_time_editing_disabled?(reservation)).to be false }
    end

    context "when the reservation is persisted" do
      context "and reserve_end_at is in the past" do
        subject(:reservation) { create(:setup_reservation, :yesterday) }

        context "and the reservation is in a cart" do
          before { reservation.order.state = :new }

          it { expect(end_time_editing_disabled?(reservation)).to be false }
        end

        context "and the reservation has been ordered" do
          before { reservation.order.state = :purchased }

          it { expect(end_time_editing_disabled?(reservation)).to be true }
        end
      end

      context "and reserve_end_at is in the future" do
        subject(:reservation) { create(:setup_reservation, :tomorrow) }

        context "and reserve_end_at is set to a time in the past but not saved" do
          before { reservation.reserve_end_at = 1.day.ago }

          it { expect(end_time_editing_disabled?(reservation)).to be false }
        end
      end
    end
  end

  describe "#start_time_editing_disabled?" do
    context "when the reservation is not persisted" do
      subject(:reservation) { Reservation.new }

      it { expect(start_time_editing_disabled?(reservation)).to be false }
    end

    context "when the reservation is persisted" do
      context "and reserve_start_at is in the past" do
        subject(:reservation) { create(:setup_reservation, :yesterday) }

        context "and the reservation is in a cart" do
          before { reservation.order.state = :new }

          it { expect(start_time_editing_disabled?(reservation)).to be false }
        end

        context "and the reservation has been ordered" do
          before { reservation.order.state = :purchased }

          it { expect(start_time_editing_disabled?(reservation)).to be true }
        end
      end

      context "and reserve_start_at is in the future" do
        subject(:reservation) { create(:setup_reservation, :tomorrow) }

        context "and reserve_start_at is set to a time in the past but not saved" do
          before { reservation.reserve_start_at = 1.day.ago }

          it { expect(start_time_editing_disabled?(reservation)).to be false }
        end
      end
    end
  end
end
