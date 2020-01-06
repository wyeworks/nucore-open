# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::DurationChangeValidations do

  subject(:validator) { described_class.new(reservation) }
  let(:reservation) { create :setup_reservation }

  describe "#start_time_not_changed" do
    let(:instrument) { create(:setup_instrument, :always_available) }
    let(:reservation) do
      create(
        :setup_reservation,
        product: instrument,
        reserve_start_at: reserve_start_at,
        reserve_end_at: reserve_end_at,
      )
    end

    context "with an upcoming reservation" do
      let(:reserve_start_at) { 5.minutes.from_now }
      let(:reserve_end_at) { 70.minutes.from_now }

      it "allows changing start time" do
        reservation.reserve_start_at = 10.minutes.from_now
        validator.valid?
        expect(validator.errors).to be_empty
      end

      it "allows shortening end time" do
        reservation.reserve_end_at = 65.minutes.from_now
        validator.valid?
        expect(validator.errors).to be_empty
      end

      context "when the product has a lock window" do
        let(:reserve_end_at) { reserve_start_at + 1.hour }

        before { reservation.product.update_attribute(:lock_window, 24) }

        context "and the original start time is outside the window" do
          let(:reserve_start_at) { 25.hours.from_now }

          context "when changing to a time inside the window" do
            before { reservation.reserve_start_at -= 2.hours }

            it "allows changing the start time" do
              expect(validator).to be_valid
              expect(validator.errors).to be_empty
            end
          end
        end

        context "and the original start time is inside the window" do
          let(:reserve_start_at) { 23.hours.from_now }

          context "when still in a cart (not yet ordered)" do
            it { expect(validator).to be_valid }
          end

          context "when ordered (no longer in a cart)" do
            before { allow(reservation).to receive(:in_cart?).and_return(false) }

            it "does not allow changing the start time" do
              reservation.reserve_start_at -= 2.hours
              reservation.reserve_end_at -= 2.hours

              expect(validator).not_to be_valid
              expect(validator.errors.full_messages)
                .to include("Reserve start at cannot change once the reservation has started")
            end

            it "is allowed to extend the reservation" do
              reservation.reserve_end_at += 10.minutes
              expect(validator).to be_valid
              expect(validator.errors).to be_empty
            end

            it "is not allowed to shorten the reservation" do
              reservation.reserve_end_at -= 5.minutes
              expect(validator).not_to be_valid
              expect(reservation.errors.full_messages)
                .to include("Duration cannot be shortened inside the lock window (24 hours)")
            end
          end
        end
      end
    end

    context "with a started reservation" do
      let(:reserve_start_at) { 30.minutes.ago }
      let(:reserve_end_at) { 40.minutes.from_now }

      context "when still in a cart (not yet ordered)" do
        it { expect(validator).to be_valid }
      end

      context "when ordered (no longer in a cart)" do
        before { allow(reservation).to receive(:in_cart?).and_return(false) }

        it "denies changing start time" do
          reservation.reserve_start_at = 40.minutes.ago
          validator.valid?
          expect(reservation.errors.full_messages)
            .to include("Reserve start at cannot change once the reservation has started")
        end

        it "denies shortening end time" do
          reservation.reserve_end_at = 35.minutes.from_now
          validator.valid?
          expect(reservation.errors.full_messages)
            .to include("Duration cannot be shortened once the reservation has started")
        end

        it "allows extending" do
          reservation.reserve_end_at += 10.minutes
          expect(validator).to be_valid
        end
      end

      context "with start time containing seconds" do
        before do
          reservation.reserve_start_at = reservation.reserve_start_at.change(sec: 45)
          reservation.save!
        end

        it "does not think start time changed" do
          reservation.reserve_start_at = 30.minutes.ago
          validator.valid?
          expect(validator.errors).to be_empty
        end
      end
    end

    context "with a past reservation" do
      let(:reservation) do
        create(
          :setup_reservation,
          reserve_start_at: 15.minutes.ago,
          reserve_end_at: 5.minutes.ago,
          product: create(:setup_instrument, min_reserve_mins: 5),
        )
      end

      context "when changing the start time" do
        before { reservation.reserve_start_at = 10.minutes.ago }

        context "when still in a cart (not yet ordered)" do
          it { expect(validator).to be_valid }
        end

        context "when ordered (no longer in a cart)" do
          before { allow(reservation).to receive(:in_cart?).and_return(false) }

          it "denies changing the start time" do
            expect(validator).not_to be_valid
            expect(reservation.errors.full_messages)
              .to include("Reserve start at cannot change once the reservation has started")
          end
        end
      end

      context "when shortening the reservation time" do
        before { reservation.reserve_end_at -= 5.minutes }

        context "when still in a cart (not yet ordered)" do
          it { expect(validator).to be_valid }
        end

        context "when ordered (no longer in a cart)" do
          before { allow(reservation).to receive(:in_cart?).and_return(false) }

          it "denies shortening the reservation time" do
            expect(validator).not_to be_valid
            expect(reservation.errors.full_messages)
              .to include("Duration cannot be shortened once the reservation has started")
          end
        end
      end
    end
  end

  describe "#copy_errors!" do
    before do
      validator.errors.add(:base, "I am an error")
      validator.copy_errors!
    end

    it "copies errors to reservation" do
      reservation.errors.full_messages.include?("I am an error")
    end
  end

  describe "#invalid?" do
    before do
      validator.errors.add(:base, "I am an error")
      validator.invalid?
    end

    it "copies errors to reservation" do
      reservation.errors.full_messages.include?("I am an error")
    end
  end

  describe "#duration_not_shortened" do
    context "with an upcoming reservation" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 1.minute.from_now,
          reserve_end_at: 61.minutes.from_now)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 30.minutes.from_now)
      end

      it { expect(validator).to be_valid }
    end

    context "with an ongoing reservation" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 30.minutes.ago,
          reserve_end_at: 30.minutes.from_now)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 1.minute.from_now)
      end

      context "when still in a cart (not yet ordered)" do
        it { expect(validator).to be_valid }
      end

      context "when ordered (no longer in a cart)" do
        before { allow(reservation).to receive(:in_cart?).and_return(false) }

        it { expect(validator).to be_invalid }
      end
    end

    context "with a past reservation" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 61.minutes.ago,
          reserve_end_at: 1.minute.ago)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 30.minutes.ago)
      end

      context "when still in a cart (not yet ordered)" do
        it { expect(validator).to be_valid }
      end

      context "when ordered (no longer in a cart)" do
        before { allow(reservation).to receive(:in_cart?).and_return(false) }

        it { expect(validator).to be_invalid }
      end
    end

    context "with a relay reservation started early" do
      before do
        reservation.assign_attributes(
          reserve_start_at: 1.minute.from_now,
          reserve_end_at: 61.minutes.from_now,
          actual_start_at: 1.minute.ago)
        reservation.save(validate: false)

        reservation.assign_attributes(reserve_end_at: 30.minutes.from_now)
      end

      context "when still in a cart (not yet ordered)" do
        it { expect(validator).to be_valid }
      end

      context "when ordered (no longer in a cart)" do
        before { allow(reservation).to receive(:in_cart?).and_return(false) }

        it { expect(validator).to be_invalid }
      end
    end

    context "with invalid data" do
      before { allow(reservation).to receive(:in_cart?).and_return(false) }

      # Validation errors will be on the reservation for being blank
      it "does not trigger the errors on the start date" do
        reservation.assign_times_from_params(reserve_start_at: "10/0/2018")
        expect(reservation.reserve_start_at).to be_blank
        expect(validator).to be_valid
      end

      it "does not trigger the errors on the end date" do
        reservation.assign_times_from_params(reserve_end_at: "10/0/2018")
        expect(reservation.reserve_end_at).to be_blank
        expect(validator).to be_valid
      end
    end
  end
end
