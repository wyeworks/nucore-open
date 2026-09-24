# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::AdminReport do
  before { allow(Settings).to receive(:admin_reports).and_return(class_names) }

  context "with registered reports" do
    let(:class_names) { ["Reports::GlobalUserRolesReport"] }

    it "derives the key from the class name" do
      expect(described_class.all.map(&:key)).to eq(["global_user_roles"])
    end

    it "finds a report by key" do
      expect(described_class.find("global_user_roles").report_class).to eq(Reports::GlobalUserRolesReport)
    end

    it "returns nil for an unknown key" do
      expect(described_class.find("unknown")).to be_nil
    end
  end

  context "with no registered reports" do
    let(:class_names) { nil }

    it { expect(described_class.all).to be_empty }
  end
end
