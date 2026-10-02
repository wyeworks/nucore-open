# frozen_string_literal: true

require "rails_helper"

RSpec.describe EstimateDetailPresenter do
  let(:facility) { create(:setup_facility) }
  let(:estimate_detail) { build_stubbed(:estimate_detail, duration:, duration_unit:) }

  subject(:presenter) { described_class.new(estimate_detail) }

  describe "#duration_with_unit" do
    context "when the duration is in minutes" do
      let(:duration) { 90 }
      let(:duration_unit) { "mins" }

      it { expect(presenter.duration_with_unit).to eq("90 Minutes") }
    end

    context "when the duration is a single minute" do
      let(:duration) { 1 }
      let(:duration_unit) { "mins" }

      it { expect(presenter.duration_with_unit).to eq("1 Minute") }
    end

    context "when the duration is in days" do
      let(:duration) { 3 }
      let(:duration_unit) { "days" }

      it { expect(presenter.duration_with_unit).to eq("3 Days") }
    end

    context "when the duration is a single day" do
      let(:duration) { 1 }
      let(:duration_unit) { "days" }

      it { expect(presenter.duration_with_unit).to eq("1 Day") }
    end

    context "when the product is not duration based" do
      let(:duration) { nil }
      let(:duration_unit) { nil }

      it { expect(presenter.duration_with_unit).to be_nil }
    end
  end

  describe "#duration_display" do
    context "when the duration is in minutes" do
      let(:duration) { 90 }
      let(:duration_unit) { "mins" }

      it "stays a bare number for the timeinput widget" do
        expect(presenter.duration_display).to eq(90)
      end
    end

    context "when the duration is in days" do
      let(:duration) { 3 }
      let(:duration_unit) { "days" }

      it { expect(presenter.duration_display).to eq("3 Days") }
    end
  end
end
