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
        let(:reservation) { build :setup_reservation, reserve_start_at: 1.hour.from_now }
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

  describe "schedule rules" do
    context "daily booking instrument" do
      subject(:reservation) do
        build(
          :setup_reservation,
          product:,
          reserve_start_at: start_at,
          reserve_end_at: end_at
        )
      end
      let(:product) { create :setup_instrument, :daily_booking }
      let(:start_at) { Time.current }
      let(:start_at_wday) { Date::ABBR_DAYNAMES[start_at.wday].downcase }
      let(:end_at) { start_at + 3.days }

      it { is_expected.to be_valid }

      context "when start at is not covered" do
        before do
          product.schedule_rules.destroy_all

          create(
            :schedule_rule,
            product:,
            "on_#{start_at_wday}" => false
          )
        end

        it "has scheduling errors" do
          is_expected.to_not be_valid

          expect(subject.errors).to be_added(:base, :no_schedule_rule)
        end
      end

      context "valid reservations" do
        before do
          product.schedule_rules.destroy_all
        end

        context "start at is cover but end at is not" do
          before do
            create(
              :schedule_rule,
              :unavailable,
              product:,
              "on_#{start_at_wday}" => true
            )
          end

          it { expect(product.schedule_rules.cover?(start_at, end_at)).to be false }
          it { expect(product.schedule_rules.cover_time?(start_at)).to be true }
          it { is_expected.to be_valid }
        end

        context "start at is cover and so is end at" do
          before do
            create(
              :schedule_rule,
              :all_day,
              product:,
            )
          end

          it { expect(product.schedule_rules.cover?(start_at, end_at)).to be true }
          it { expect(product.schedule_rules.cover_time?(start_at)).to be true }
          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe "daily booking min/max length validations" do
    subject(:reservation) do
      build(
        :setup_reservation,
        product:,
        reserve_start_at: start_at,
        reserve_end_at: end_at
      )
    end

    let(:product) { create :setup_instrument, :daily_booking }
    let(:start_at) { Time.current }

    describe "satisfies_maximum_length" do
      context "when max_reserve_days is not set" do
        let(:end_at) { start_at + 10.days }

        it { is_expected.to be_valid }
      end

      context "when max_reserve_days is set" do
        before { product.update!(max_reserve_days: 4) }

        context "when reservation is within max days" do
          let(:end_at) { start_at + 3.days }

          it { is_expected.to be_valid }
        end

        context "when reservation equals max days" do
          let(:end_at) { start_at + 4.days }

          it { is_expected.to be_valid }
        end

        context "when reservation exceeds max days" do
          let(:end_at) { start_at + 6.days }

          it "is invalid with too_long_days error" do
            is_expected.not_to be_valid
            expect(reservation.errors).to be_added(:base, :too_long_days, length: 4)
          end
        end
      end
    end

    describe "satisfies_minimum_length" do
      context "when min_reserve_days is not set" do
        let(:end_at) { start_at + 1.day }

        it { is_expected.to be_valid }
      end

      context "when min_reserve_days is set" do
        before { product.update!(min_reserve_days: 2) }

        context "when reservation meets minimum days" do
          let(:end_at) { start_at + 3.days }

          it { is_expected.to be_valid }
        end

        context "when reservation equals minimum days" do
          let(:end_at) { start_at + 2.days }

          it { is_expected.to be_valid }
        end

        context "when reservation is less than minimum days" do
          let(:end_at) { start_at + 1.day }

          it "is invalid with too_short_days error" do
            is_expected.not_to be_valid
            expect(reservation.errors).to be_added(:base, :too_short_days, length: 2)
          end
        end
      end
    end
  end
end
