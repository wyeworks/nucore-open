# frozen_string_literal: true

require "rails_helper"

RSpec.describe NextAvailableReservationFinder do
  let(:user) { build(:user) }
  subject(:reservation) { described_class.new(instrument).next_available_for(user, user) }

  describe "time scheduled instrument" do
    let(:instrument) { build(:instrument, min_reserve_mins: 0) }

    describe "without a next available reservation" do

      before do
        expect(instrument).to receive(:next_available_reservation).and_return(nil)
      end

      it "has a reservation starting around now" do
        expect(reservation.reserve_start_at).to be_within(1.minute).of(Time.current)
      end

      it "is thirty minutes long" do
        expect(reservation.duration_mins).to eq(30)
      end

      it "is on the right product" do
        expect(reservation.product).to eq(instrument)
      end
    end
  end

  describe "daily booking instrument" do
    let(:instrument) do
      create(
        :setup_instrument,
        :always_available,
        :daily_booking
      )
    end

    describe "with an empty schedule" do
      it "has a duration of 1 day when no minimum" do
        expect(reservation.duration_mins.minutes).to eq 1.day
      end

      describe "reservation duration" do
        before { instrument.update(min_reserve_days: 4) }

        it "has a correct duration in minutes" do
          expect(reservation.duration_mins.minutes).to eq instrument.min_reserve_days.days
        end

        it "has a correct duration in days" do
          expect(reservation.duration_days).to eq instrument.min_reserve_days
        end
      end

      it "returns a schedule as soon as possible" do
        next_available_time = 1.minute.from_now

        expect(reservation.reserve_start_at).to eq next_available_time
      end

      it "sets reserve_end_at correctly" do
        expect(reservation.reserve_end_at).to eq(reservation.reserve_start_at + 1.day)
      end
    end
  end
end
