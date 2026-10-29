# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ReservationRowDurationCalculator do
  let(:calculator) do
    described_class.new(reservation,
                        start_time:,
                        end_time:)
  end

  let(:reservation) do
    FactoryBot.build(:offline_reservation,
                     reserve_start_at:,
                     reserve_end_at:)
  end

  let(:start_time) { Date.new(2016, 1, 1).beginning_of_day }
  let(:end_time) { Date.new(2016, 1, 3).end_of_day }

  describe "#duration_in_seconds" do
    subject(:duration_in_seconds) { calculator.duration_in_seconds }

    context "when the reservation began before the start_time" do
      let(:reserve_start_at) { start_time - 1.day }

      context "when the reservation ended before the end_time" do
        let(:reserve_end_at) { start_time + 12.hours }

        it { is_expected.to eq(43_200).and eq(12.hours) }
      end

      context "when the reservation ended after the end_time" do
        let(:reserve_end_at) { end_time + 1.day }

        it { is_expected.to eq(259_200).and eq(3.days) }
      end

      context "when the reservation has not yet ended (is ongoing)" do
        let(:reserve_end_at) { nil }

        it { is_expected.to eq(259_200).and eq(3.days) }
      end
    end

    context "when the reservation began after the start_time" do
      let(:reserve_start_at) { start_time + 1.day + 12.hours }

      context "when the reservation ended before the end_time" do
        let(:reserve_end_at) { reserve_start_at + 1.hour }

        it { is_expected.to eq(3600).and eq(1.hour) }
      end

      context "when the reservation ended after the end_time" do
        let(:reserve_end_at) { end_time + 1.day }

        it { is_expected.to eq(129_600).and eq(1.day + 12.hours) }
      end

      context "when the reservation has not yet ended (is ongoing)" do
        let(:reserve_end_at) { nil }

        it { is_expected.to eq(129_600).and eq(1.day + 12.hours) }
      end
    end
  end
end
