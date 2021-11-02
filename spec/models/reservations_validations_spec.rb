# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::Validations do

  subject(:reservation) { build :setup_reservation }

  let(:now) { Time.zone.now }

  it { is_expected.to validate_presence_of(:reserve_start_at) }

  it "validates with #duration_is_interval" do
    expect(reservation).to receive :duration_is_interval
    reservation.save
  end

  it "does not produce an error if the duration of the reservation is a factor of the instrument interval" do
    reservation.product.update_attribute :reserve_interval, 15
    expect(reservation.errors).to be_blank
    reservation.update reserve_start_at: now, reserve_end_at: now + 1.hour
    expect(reservation.errors).to be_blank
  end

  it "does not produce an error if the duration of the reservation is not a factor of the instrument interval" do
    reservation.product.update_attribute :reserve_interval, 15
    expect(reservation.errors).to be_blank
    reservation.update reserve_start_at: now, reserve_end_at: now + 1.hour + 5.minutes
    expect(reservation.errors[:base]).to be_present
  end

  describe "starts_before_cutoff" do
    context "when there is a cutoff" do
      before :each do
        reservation.product.update_attribute(:cutoff_hours, 2)
      end

      context "when reservation is after the cutoff" do
        let(:reservation) { build :setup_reservation, reserve_start_at: 3.hours.from_now }
        let(:user) { reservation.order_detail.created_by_user }

        it "saves the reservation" do
          expect(reservation.save_as_user(user)).to be(true)
        end
      end

      context "when reservation is before the cutoff" do
        let(:reservation) { build :setup_reservation, reserve_start_at: Time.zone.now + 1.hour }
        let(:user) { reservation.order_detail.created_by_user }

        it "does not save reservation" do
          expect(reservation.save_as_user(user)).to be(false)
          expect(reservation.persisted?).to eq(false)
          expect(reservation.errors).to be_added(:reserve_start_at, :after_cutoff, hours: 2)
        end

        context "when an admin made the reservation" do
          let(:user) { create(:user, :facility_administrator, facility: reservation.product.facility) }

          it "saves the reservation" do
            expect(reservation.save_as_user(user)).to be(true)
          end
        end
      end
    end
  end

  describe "conditionally run validations" do
    context "with reserve_start_at, reserve_end_at, and reservation_changed? is true" do
      it "runs conditional validations" do
        expect(reservation).to receive :does_not_conflict_with_other_user_reservation
        reservation.save
      end
    end

    context "with missing reserve_start_at" do
      it "does not run conditional validations" do
        expect(reservation).not_to receive :does_not_conflict_with_other_user_reservation
        reservation.update(reserve_start_at: nil)
      end
    end
  end
end
