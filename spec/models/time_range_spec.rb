# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimeRange do
  let(:range) { described_class.new(start_at, end_at) }

  describe "duration_mins" do
    subject(:duration_mins) { range.duration_mins }

    describe "a normal interval" do
      let(:start_at) { Time.current }
      let(:end_at) { start_at + 30.minutes }
      it { is_expected.to eq(30) }
    end

    describe "when it crosses only two minutes, and is more than a minute" do
      let(:start_at) { Time.current.change(sec: 10) }
      let(:end_at) { start_at + 80.seconds }

      it { is_expected.to eq(1) }
    end

    describe "when they cross two minutes, but still less than a minute" do
      let(:start_at) { Time.current.change(sec: 45) }
      let(:end_at) { start_at + 30.seconds }

      it { is_expected.to eq(1) }
    end

    describe "when two times are within the same minute" do
      let(:start_at) { Time.current.change(sec: 10) }
      let(:end_at) { start_at.change(sec: 45) }

      it "always returns at least one" do
        expect(duration_mins).to eq(1)
      end
    end
  end

  describe "to_s" do
    subject(:string) { range.to_s }

    describe "normal case" do
      let(:start_at) { Time.zone.local(2017, 4, 26, 14, 0, 15) }
      let(:end_at) { start_at + 30.minutes }
      it { is_expected.to eq("Wed, 04/26/2017 2:00 PM - 2:30 PM") }
    end

    describe "when the range spans a day" do
      let(:start_at) { Time.zone.local(2017, 4, 26, 14, 0, 15) }
      let(:end_at) { start_at + 26.hours }
      it { is_expected.to eq("Wed, 04/26/2017 2:00 PM - Thu, 04/27/2017 4:00 PM") }
    end

    describe "when the day of the month is the same" do
      let(:start_at) { Time.zone.local(2017, 4, 26, 14, 0, 15) }
      let(:end_at) { Time.zone.local(2017, 5, 26, 14, 0, 15) }
      it { is_expected.to eq("Wed, 04/26/2017 2:00 PM - Fri, 05/26/2017 2:00 PM") }
    end

    describe "when it spans midnight in UTC" do
      around do |example|
        Time.use_zone("Central Time (US & Canada)") { example.call }
      end
      let(:start_at) { Time.zone.local(2017, 4, 26, 19, 0) }
      let(:end_at) { Time.zone.local(2017, 4, 26, 22, 0) }
      it { is_expected.to eq("Wed, 04/26/2017 7:00 PM - 10:00 PM") }
    end

    describe "when missing the start time" do
      let(:start_at) { nil }
      let(:end_at) { Time.zone.local(2017, 4, 26, 14, 0, 15) }
      it { is_expected.to eq("??? - Wed, 04/26/2017 2:00 PM") }
    end

    describe "when missing the end time" do
      let(:start_at) { Time.zone.local(2017, 4, 26, 14, 0, 15) }
      let(:end_at) { nil }
      it { is_expected.to eq("Wed, 04/26/2017 2:00 PM - ???") }
    end

    describe "when missing both times" do
      let(:start_at) { nil }
      let(:end_at) { nil }
      it { is_expected.to eq("??? - ???") }
    end
  end

end
