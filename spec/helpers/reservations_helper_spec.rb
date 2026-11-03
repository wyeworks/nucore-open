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

  describe "#authorized_to_cancel?" do
    subject { authorized_to_cancel?(reservation) }

    let(:facility) { create(:setup_facility) }
    let(:instrument) { create(:setup_instrument, facility:) }
    let(:reservation) { create(:purchased_reservation, product: instrument) }

    context "as the reservation's owner" do
      let(:current_user) { reservation.order_detail.user }

      it { is_expected.to be true }
    end

    context "as a facility director" do
      let(:current_user) { create(:user, :facility_director, facility:) }

      it { is_expected.to be true }
    end

    context "as an unrelated user" do
      let(:current_user) { create(:user) }

      it { is_expected.to be false }
    end

    context "with granular permissions", feature_setting: { granular_permissions: true } do
      let(:current_user) { create(:user) }

      context "and only read access" do
        before { create(:facility_user_permission, user: current_user, facility:, read_access: true) }

        it { is_expected.to be false }
      end

      context "and order management" do
        before { create(:facility_user_permission, user: current_user, facility:, read_access: true, order_management: true) }

        it { is_expected.to be true }
      end
    end

    context "when the reservation has no order detail" do
      let(:current_user) { create(:user) }
      let(:reservation) { create(:admin_reservation, product: instrument) }

      it { is_expected.to be false }
    end
  end
end
