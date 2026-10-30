# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimelineHelper do
  before :each do
    @display_datetime = Time.zone.now
  end

  context "datetime_left_position" do
    it "should return 0 if the start time is yesterday" do
      expect(datetime_left_position(@display_datetime, Time.zone.now.beginning_of_day - 1.hour)).to eq("0px")
    end
    it "should return 60 for 8am" do
      eight_pm = Time.zone.now.beginning_of_day.change(hour: 8)
      expect(datetime_left_position(@display_datetime, eight_pm)).to eq("#{(480 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor}px")
    end
  end

  context "datetime_width" do
    before :each do
      @reservation = Reservation.new(reserve_start_at: Time.zone.now.change(hour: 8, min: 0),
                                     reserve_end_at: Time.zone.now.change(hour: 10, min: 0))
      @reservation_spans_yesterday = Reservation.new(reserve_start_at: 1.day.ago.change(hour: 23, min: 0),
                                                     reserve_end_at: Time.zone.now.change(hour: 2, min: 0))
      @reservation_spans_tomorrow = Reservation.new(reserve_start_at: Time.zone.now.change(hour: 23, min: 0),
                                                    reserve_end_at: 1.day.from_now.change(hour: 3, min: 0))
    end
    it "should return a full width if start and end are in the same day" do
      width = (120 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor
      expect(@reservation.duration_mins).to eq(120)
      expect(datetime_width(@display_datetime, @reservation.reserve_start_at, @reservation.reserve_end_at)).to eq("#{width}px")
    end

    it "should be shorter if it starts before midnight" do
      expect(@reservation_spans_yesterday.duration_mins).to eq(180)
      width = (120 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor
      expect(datetime_width(@display_datetime, @reservation_spans_yesterday.reserve_start_at, @reservation_spans_yesterday.reserve_end_at)).to eq("#{width}px")
    end

    it "should be shorter if it ends after midnight" do
      expect(@reservation_spans_tomorrow.duration_mins).to eq(240)
      width = (60 * TimelineHelper::MINUTE_TO_PIXEL_RATIO).floor
      expect(datetime_width(@display_datetime, @reservation_spans_tomorrow.reserve_start_at, @reservation_spans_tomorrow.reserve_end_at)).to eq("#{width}px")
    end
  end

  context "spans_midnight_class" do
    before :each do
      @reservation = Reservation.new(reserve_start_at: Time.zone.now.change(hour: 8, min: 0),
                                     reserve_end_at: Time.zone.now.change(hour: 10, min: 0))
      @reservation_spans_yesterday = Reservation.new(reserve_start_at: 1.day.ago.change(hour: 23, min: 0),
                                                     reserve_end_at: Time.zone.now.change(hour: 2, min: 0))
      @reservation_spans_tomorrow = Reservation.new(reserve_start_at: Time.zone.now.change(hour: 23, min: 0),
                                                    reserve_end_at: 1.day.from_now.change(hour: 3, min: 0))
    end
    it "should have nothing for a normal reservation" do
      expect(spans_midnight_class(@reservation.reserve_start_at, @reservation.reserve_end_at)).to be_blank
    end

    it "should return the right class for one that spans yesterday" do
      expect(spans_midnight_class(@reservation_spans_yesterday.reserve_start_at, @reservation_spans_yesterday.reserve_end_at)).to eq(["runs_into_yesterday"])
    end
    it "should return the right class for one that spans tomorrow" do
      expect(spans_midnight_class(@reservation_spans_tomorrow.reserve_start_at, @reservation_spans_tomorrow.reserve_end_at)).to eq(["runs_into_tomorrow"])
    end
  end
end
