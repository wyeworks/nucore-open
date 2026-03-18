# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recurrence do
  let(:recurrence) { Recurrence.new(30.days.ago, 30.days.ago + 1.hour, until_time: 30.days.from_now) }

  describe "#daily" do
    it "creates repeats 1 day apart" do
      repeats = recurrence.daily.take(2).map(&:start_time)
      expect(repeats[1] - repeats[0]).to eq 1.day
    end
  end

  describe "#weekdays" do
    let(:repeats) { recurrence.weekdays.take(8).map(&:start_time) }

    it "only includes weekdays", :aggregate_failures do
      expect(repeats.map(&:wday)).to include(*1..5)
      expect(repeats.map(&:wday)).not_to include(0, 6)
    end
  end

  describe "#weekly" do
    it "creates repeats 1 week apart" do
      repeats = recurrence.weekly.take(2).map(&:start_time)
      expect(repeats[1] - repeats[0]).to eq 1.week
    end
  end

  describe "#monthly" do
    it "creates repeats 1 month apart" do
      repeats = recurrence.monthly.take(2).map(&:start_time)
      expect(repeats[1] - repeats[0]).to be >= 28.days
      expect(repeats[1] - repeats[0]).to be <= 31.days
    end
  end

end
