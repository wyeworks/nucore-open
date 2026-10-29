# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::UserNoteMode do
  describe "hidden" do
    subject(:mode) { described_class["hidden"] }

    it { is_expected.to be_a(described_class) }
    it { is_expected.not_to be_visible }
    it { is_expected.not_to be_required }

    it "renders a label" do
      expect(mode.to_label).to eq("No")
    end

    it "is equal to another instance of the same mode" do
      expect(mode).to eq(described_class["hidden"])
    end

    it "is not equal to others" do
      expect(mode).not_to eq(described_class["random"])
      expect(mode).not_to eq(described_class["required"])
    end

    it "is equal to its string" do
      expect(mode).to eq("hidden")
    end
  end

  describe "optional" do
    subject(:mode) { described_class["optional"] }

    it { is_expected.to be_visible }
    it { is_expected.not_to be_required }

    it "renders a label" do
      expect(mode.to_label).to eq("Optional")
    end

    it "is equal to another instance of the same mode" do
      expect(mode).to eq(described_class["optional"])
    end

    it "is not equal to others" do
      expect(mode).not_to eq(described_class["random"])
      expect(mode).not_to eq(described_class["required"])
    end

    it "is equal to its string" do
      expect(mode).to eq("optional")
    end
  end

  describe "required" do
    subject(:mode) { described_class["required"] }

    it { is_expected.to be_visible }
    it { is_expected.to be_required }

    it "renders a label" do
      expect(mode.to_label).to eq("Required")
    end

    it "is equal to another instance of the same mode" do
      expect(mode).to eq(described_class["required"])
    end

    it "is not equal to others" do
      expect(mode).not_to eq(described_class["random"])
      expect(mode).not_to eq(described_class["optional"])
    end

    it "is equal to its string" do
      expect(mode).to eq("required")
    end
  end

  describe "an invalid value" do
    it "returns an invalid mode from .[]" do
      expect(described_class["random"].to_s).to include("Invalid User Note Mode")
    end

    it "raises an error from the constructor" do
      expect { described_class.new("random") }.to raise_error(ArgumentError, "Invalid value: random")
    end
  end

  describe "built with an instance of UserNoteMode" do
    let(:mode) { described_class[described_class["optional"]] }

    it "is idempotent" do
      expect(mode).to eq(described_class["optional"])
    end
  end
end
