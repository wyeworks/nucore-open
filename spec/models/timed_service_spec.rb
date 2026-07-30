# frozen_string_literal: true

require "rails_helper"

RSpec.describe TimedService do
  subject(:timed_service) { build(:setup_timed_service) }

  it { is_expected.to be_valid }

  describe "pricing_mode" do
    it "defaults to the standard mode" do
      expect(timed_service.pricing_mode).to eq(TimedService::Pricing::STANDARD)
    end

    it "allows the duration mode" do
      timed_service.pricing_mode = TimedService::Pricing::DURATION

      expect(timed_service).to be_valid
    end
  end

  describe "#duration_pricing_mode?" do
    it "is false in the standard mode" do
      expect(timed_service).not_to be_duration_pricing_mode
    end

    it "is true in the duration mode" do
      timed_service.pricing_mode = TimedService::Pricing::DURATION

      expect(timed_service).to be_duration_pricing_mode
    end
  end
end
