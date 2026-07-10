# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidFulfilledAtDate do
  subject(:fulfilled_at) { described_class.new(string) }
  let(:string) { date.iso8601 }

  describe "with a date in the future" do
    let(:date) { 1.day.from_now.to_date }

    it "returns the time" do
      expect(fulfilled_at.to_time).to eq(date + 12.hours)
    end

    it "is not valid" do
      expect(fulfilled_at).to be_invalid
      expect(fulfilled_at.errors).to be_added(:base, :in_future)
    end
  end

  describe "with a date far in the past" do
    let(:date) { 3.years.ago.to_date }

    it "returns the time" do
      expect(fulfilled_at.to_time).to eq(date + 12.hours)
    end

    it "is not valid" do
      expect(fulfilled_at).to be_invalid
      expect(fulfilled_at.errors).to be_added(:base, :too_far_in_past)
    end
  end

  describe "with an invalid format" do
    let(:string) { "2/432/198" }

    it "does not return a time" do
      expect(fulfilled_at.to_time).to be_nil
    end

    it "is not valid" do
      expect(fulfilled_at).to be_invalid
      expect(fulfilled_at.errors).to be_added(:base, :invalid)
    end
  end
end
