# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservations::DateSupport do
  subject(:reservation) do
    build_stubbed(
      :reservation,
      reserve_start_at: reserve_start_at,
      reserve_end_at: reserve_end_at,
      actual_start_at: actual_start_at,
      actual_end_at: actual_end_at,
    )
  end

  let(:reserve_start_at) { nil }
  let(:reserve_end_at) { nil }
  let(:actual_start_at) { nil }
  let(:actual_end_at) { nil }

  describe "#actual_duration_mins" do
    context "when @actual_duration_mins is set" do
      before { reservation.actual_duration_mins = minutes }

      context "to a string representation of an integer" do
        let(:minutes) { "5" }

        it "converts @actual_duration_mins to an integer, as-is" do
          expect(reservation.actual_duration_mins).to eq(5)
        end
      end

      context "to a string representation of a float" do
        context "where the difference is < 0.5" do
          let(:minutes) { "0.25" }

          it "has no minimum and rounds down to 0" do
            expect(reservation.actual_duration_mins).to eq(0)
          end
        end

        context "where the fraction is < 0.5" do
          let(:minutes) { "1.25" }

          it "truncates the fraction" do
            expect(reservation.actual_duration_mins).to eq(1)
          end
        end

        context "where the fraction is 0.5" do
          let(:minutes) { "1.5" }

          it "truncates the fraction" do
            expect(reservation.actual_duration_mins).to eq(1)
          end
        end

        context "where the fraction is > 0.5" do
          let(:minutes) { "1.99" }

          it "truncates the fraction" do
            expect(reservation.actual_duration_mins).to eq(1)
          end
        end
      end
    end

    context "when @actual_duration_mins is unset" do
      context "and actual_start_at is set to 00:00:59" do
        let(:actual_start_at) { Time.zone.parse("2015-01-01T00:00:59") }

        [
          ["2015-01-01T00:01:01", 1],
          ["2015-01-01T00:01:59", 1],
          ["2015-01-01T00:02:01", 2],
          ["2015-01-01T00:02:59", 2],
          ["2015-01-01T01:00:00", 60],
          ["2015-01-01T01:00:59", 60],
        ]
          .each do |timestring, expected_minutes|
          context "and the actual_end_at is #{timestring}" do
            let(:actual_end_at) { Time.zone.parse(timestring) }

            it "returns #{expected_minutes}" do
              expect(reservation.actual_duration_mins).to eq(expected_minutes)
            end
          end
        end

        context "and actual_end_at is unset" do
          [
            ["2015-01-01T00:01:01", 1],
            ["2015-01-01T00:01:59", 1],
            ["2015-01-01T00:02:01", 2],
            ["2015-01-01T00:02:59", 2],
            ["2015-01-01T01:00:00", 60],
            ["2015-01-01T01:00:59", 60],
          ]
            .each do |timestring, expected_minutes|
            context "and the base_time is #{timestring}" do
              it "returns #{expected_minutes}" do
                expect(reservation.actual_duration_mins).to be_blank
              end
            end
          end
        end
      end

      context "and actual_start_at is unset" do
        it "returns 0" do
          expect(reservation.actual_duration_mins).to eq(0)
        end
      end
    end
  end

  describe "#assign_times_from_params" do
    subject(:reservation) { create(:purchased_reservation, :started_early) }

    context "with a running reservation" do
      before(:each) do
        reservation.assign_times_from_params(
          reserve_start_date: "04/17/2015",
          reserve_start_hour: "9",
          reserve_start_min: "0",
          reserve_start_meridian: "AM",
          duration_mins: "60")
      end

      it "updates start date" do
        expect(reservation.reserve_start_date).to eq("04/17/2015")
      end

      it "updates start hour" do
        expect(reservation.reserve_start_hour).to eq(9)
      end

      it "updates start min" do
        expect(reservation.reserve_start_min).to eq(0)
      end

      it "updates start meridian" do
        expect(reservation.reserve_start_meridian).to eq("AM")
      end

      it "updates duration mins" do
        expect(reservation.duration_mins).to eq(60)
      end

      it "updates reserve start at" do
        expect(reservation.reserve_start_at)
          .to eq(Time.zone.local(2015, 4, 17, 9, 0, 0))
      end

      it "updates reserve end at" do
        expect(reservation.reserve_end_at)
          .to eq(Time.zone.local(2015, 4, 17, 10, 0, 0))
      end
    end
  end

  describe "#duration_mins" do
    context "when @duration_mins is set" do
      before { reservation.duration_mins = minutes }

      context "to the string representation of an integer" do
        let(:minutes) { "5" }

        it "returns @duration_mins as-is" do
          expect(reservation.duration_mins).to eq(5)
        end
      end

      context "to the string reservation of a float" do
        context "where the fraction is < 0.5" do
          let(:minutes) { "1.25" }

          it "truncates the fraction" do
            expect(reservation.duration_mins).to eq(1)
          end
        end

        context "where the fraction is 0.5" do
          let(:minutes) { "1.5" }

          it "truncates the fraction" do
            expect(reservation.duration_mins).to eq(1)
          end
        end

        context "where the fraction is > 0.5" do
          let(:minutes) { "1.99" }

          it "truncates the fraction" do
            expect(reservation.duration_mins).to eq(1)
          end
        end
      end
    end

    context "when @duration_mins is unset" do
      context "when reserve_start_at is set to 00:00:59" do
        let(:reserve_start_at) { Time.zone.parse("2015-01-01T00:00:59") }

        [
          ["2015-01-01T00:01:01", 1],
          ["2015-01-01T00:01:59", 1],
          ["2015-01-01T00:02:01", 2],
          ["2015-01-01T00:02:59", 2],
          ["2015-01-01T01:00:00", 60],
          ["2015-01-01T01:00:59", 60],
        ]
          .each do |timestring, expected_minutes|
          context "and reserve_end_at is #{timestring}" do
            let(:reserve_end_at) { Time.zone.parse(timestring) }

            it "returns #{expected_minutes}" do
              expect(reservation.duration_mins).to eq(expected_minutes)
            end
          end
        end

        context "and reserve_end_at is unset" do
          it { expect(reservation.duration_mins).to eq(0) }
        end
      end

      context "when reserve_start_at is unset" do
        it { expect(reservation.duration_mins).to eq(0) }
      end
    end
  end

  describe "#has_actual_times?" do
    it "returns false when actual_start_at is blank" do
      reservation.actual_start_at = nil
      expect(reservation.has_actual_times?).to be false
    end

    it "returns false when actual_end_at is blank" do
      reservation.actual_end_at = nil
      expect(reservation.has_actual_times?).to be false
    end

    it "returns true when actual_start_at and actual_end_at are set" do
      reservation.assign_attributes(
        actual_start_at: 45.minutes.ago,
        actual_end_at: 15.minutes.ago,
      )
      expect(reservation.has_actual_times?).to be true
    end
  end

  describe "#has_reserves_times?" do
    it "returns false when reserve_start_at is blank" do
      reservation.reserve_start_at = nil
      expect(reservation.has_reserved_times?).to be false
    end

    it "returns false when reserve_end_at is blank" do
      reservation.reserve_end_at = nil
      expect(reservation.has_reserved_times?).to be false
    end

    it "returns true when reserve_start_at and reserve_end_at are set" do
      reservation.assign_attributes(
        reserve_start_at: 45.minutes.ago,
        reserve_end_at: 15.minutes.ago,
      )
      expect(reservation.has_reserved_times?).to be true
    end
  end
end
