# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliate do

  it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  it { is_expected.to validate_presence_of(:name) }

  it "maintains 'Other' as a constant", :aggregate_failures do
    expect(Affiliate.OTHER).to eq(Affiliate.find_by(name: "Other"))
    expect(Affiliate.OTHER).to be_subaffiliates_enabled
  end

  it "does not allow OTHER to be destroyed" do
    Affiliate.OTHER.destroy
    expect(Affiliate.OTHER).not_to be_destroyed
  end

  it "allows non-OTHER affiliates to be destroyed" do
    affiliate = Affiliate.create!(name: "aff1")
    affiliate.destroy
    expect(affiliate).to be_destroyed
  end

  describe "#other?" do
    context "when it is the 'Other' affiliate" do
      subject(:affiliate) { Affiliate.OTHER }

      it { is_expected.to be_other }
    end

    context "with it is not the 'Other' affiliate" do
      subject(:affiliate) { Affiliate.new(name: "aff2") }

      it { is_expected.not_to be_other }
    end
  end
end
