# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountPriceGroupMembersHelper do
  describe "additional_results_notice" do
    it "returns nil if an input is missing" do
      expect(additional_results_notice(count: nil, limit: 25)).to be_nil
      expect(additional_results_notice(count: 14, limit: nil)).to be_nil
      expect(additional_results_notice(count: 14, limit: 25)).to be_nil
    end

    it "returns nil if the accounts_count isn't over the limit" do
      expect(additional_results_notice(count: 12, limit: 25)).to be_nil
    end

    it "returns a notice if accounts_count is over the limit" do
      count = 120
      limit = 25
      text = "<p class='notice'>#{count - limit} more payment sources exist, try refining your search.</p>"

       expect(additional_results_notice(count: 120, limit: 25)).to eq text
    end
  end
end
