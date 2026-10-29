# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateHelper do
  describe "#parse_usa_import_date" do
    context "with bad dates" do
      %w[05012012 garbage 11/31/2012 5-Apr-13 31/1/2014 2014-Jan-1 3/3/13].each do |date_string|
        it "considers '#{date_string}' a bad date" do
          expect(parse_usa_import_date(date_string)).to be_nil
        end
      end
    end

    context "with valid dates" do
      %w[1/1/2014 3/31/2014 10/2/2014 12/31/2014].each do |date_string|
        it "considers '#{date_string}' a valid date" do
          expect(parse_usa_import_date(date_string)).to be_present
        end
      end

      it "parses dates in USA-style MM/DD/YYYY format" do
        expect(parse_usa_import_date("8/12/2014").day).to be 12
        expect(parse_usa_import_date("8/12/2014").month).to be 8
        expect(parse_usa_import_date("8/12/2014").year).to be 2014

        expect(parse_usa_import_date("12/8/2014").day).to be 8
        expect(parse_usa_import_date("12/8/2014").month).to be 12
        expect(parse_usa_import_date("12/8/2014").year).to be 2014
      end

      context "when running in the Eastern time zone", time_zone: "Eastern Time (US & Canada)" do
        it "returns beginning_of_day (midnight) in the local zone" do
          expect(parse_usa_import_date("05/01/2014").to_s)
            .to eq("2014-05-01 00:00:00 -0400")
        end
      end
    end
  end

  describe "#parse_usa_date" do
    context "given bad dates" do
      ["05012012", "somegarbage", "11/31/2012", nil, "9/", "5/1/20114", "1/4/16"].each do |bad_date_string|
        it "does not raise error for: #{bad_date_string}" do
          expect { parse_usa_date(bad_date_string) }.not_to raise_error
        end

        it "returns nil for #{bad_date_string}" do
          expect(parse_usa_date(bad_date_string)).to be_nil
        end
      end
    end

    context "given valid dates" do
      it "parses a date with month and day in USA style" do
        expect(parse_usa_date("05/10/2012")).to eq(Time.zone.parse("2012-05-10"))
      end

      it "parses a usa formatted date with single digits properly" do
        expect(parse_usa_date("5/1/2012")).to eq(Time.zone.parse("2012-05-01"))
      end

      it "can handle leading/trailing whitespace" do
        expect(parse_usa_date("  5/1/2012  ")).to eq(Time.zone.parse("2012-05-01"))
      end
    end

    context "with a time as well" do
      it "parses a date with month and day in USA style" do
        expect(parse_usa_date("05/10/2012", "3:17 PM")).to eq(Time.zone.parse("2012-05-10 15:17"))
      end

      it "parses a date/time in 24 hour format" do
        expect(parse_usa_date("05/10/2012", "15:17")).to eq(Time.zone.parse("2012-05-10 15:17"))
      end

      it "returns nil with invalid time" do
        expect(parse_usa_date("5/10/2012", "34:23 FM")).to be_nil
      end

      it "returns nil for valid time, but nil input" do
        expect(parse_usa_date(nil, "3:17 PM")).to be_nil
      end
    end

    # TODO: These should not be officially supported, but many tests rely on this
    # behavior. In the main app, this method is only every called with user input,
    # usually coming from a datepicker. Until we clean the tests up, we support
    # these formats.
    describe "semi-valid inputs" do
      it "returns the datetime when given a Date" do
        date = Date.new(2012, 5, 1)
        expect(parse_usa_date(date)).to eq(Time.zone.parse("2012-05-01"))
      end

      it "returns the datetime when given a Date and time string" do
        date = Date.new(2012, 5, 1)
        expect(parse_usa_date(date, "3:17 PM")).to eq(Time.zone.parse("2012-05-01 15:17"))
      end

      it "returns the datetime for YYYY-MM-DD format" do
        expect(parse_usa_date("2012-05-01")).to eq(Time.zone.parse("2012-05-01"))
      end

      it "returns the datetime for YYYY-MM-DD format with a time" do
        expect(parse_usa_date("2012-05-01", "4:19 PM")).to eq(Time.zone.parse("2012-05-01 16:19"))
      end
    end
  end

  describe "#human_date"
  describe "#human_time"

  describe "time_ceil" do
    it "rounds up to the nearest 5 minute" do
      expect(time_ceil(Time.zone.parse("2013-08-15 12:03"))).to eq(Time.zone.parse("2013-08-15 12:05"))
    end

    it "drops the seconds before rounding" do
      expect(time_ceil(Time.zone.parse("2013-08-15 12:05:30"))).to eq(Time.zone.parse("2013-08-15 12:05"))
    end

    it "does not round up if already at 5 minutes" do
      expect(time_ceil(Time.zone.parse("2013-08-15 12:05"))).to eq(Time.zone.parse("2013-08-15 12:05"))
    end

    it "rounds up to 15 minute" do
      expect(time_ceil(Time.zone.parse("2013-08-15 12:05"), 15.minutes)).to eq(Time.zone.parse("2013-08-15 12:15"))
    end

    it "rounds up to an hour" do
      expect(time_ceil(Time.zone.parse("2013-08-15 12:05"), 1.hour)).to eq(Time.zone.parse("2013-08-15 13:00"))
    end
  end
end
