# frozen_string_literal: true

require "rails_helper"

RSpec.describe SettingsHelper do
  context "fiscal year" do
    before :each do
      allow(Settings.financial).to receive(:fiscal_year_begins).and_return("03-01")
    end

    it "should get the right fiscal year for a year" do
      expect(SettingsHelper.fiscal_year(2020)).to eq(Time.zone.parse("2020-03-01").beginning_of_day)
      # Make sure our parsing is happening correctly (i.e. it's not mixing up the month and day)
      expect(SettingsHelper.fiscal_year(2020).strftime("%b %-d %Y")).to eq("Mar 1 2020")
    end

    it "should get the previous year for dates before the start" do
      expect(SettingsHelper.fiscal_year_beginning(Time.zone.local(2010, 2, 5))).to eq(Time.zone.parse("2009-03-01").beginning_of_day)
      # Make sure we can compare either DateTime or Time
      expect(SettingsHelper.fiscal_year_beginning(Time.zone.parse("2010-02-05"))).to eq(Time.zone.parse("2009-03-01").beginning_of_day)
    end

    it "should the the next year for dates after the start" do
      expect(SettingsHelper.fiscal_year_beginning(Time.zone.local(2010, 5, 5))).to eq(Time.zone.parse("2010-03-01").beginning_of_day)
    end

    it "should set the end of the fiscal year for dates before the start" do
      expect(SettingsHelper.fiscal_year_end(Time.zone.local(2014, 2, 5))).to eq(Time.zone.parse("2014-02-28").end_of_day)
    end

    it "should set the end of the fiscal year for dates after the start" do
      expect(SettingsHelper.fiscal_year_end(Time.zone.local(2014, 5, 14))).to eq(Time.zone.parse("2015-02-28").end_of_day)
    end
  end

  describe "feature_on" do
    it "raises an error if the feature does not exist" do
      expect { SettingsHelper.feature_on?(:nonexistent_feature) }.to raise_error(KeyError)
    end
  end
end
