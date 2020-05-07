# frozen_string_literal: true

require "rails_helper"

RSpec.describe Nucore::Database::DateHelper do
  class DateHelperClass

    include Nucore::Database::DateHelper

  end

  describe "#parse_2_digit_year_date" do
    def parse_date(date_string)
      DateHelperClass.parse_2_digit_year_date(date_string).strftime("%Y-%m-%d")
    end

    it "handles a missing leading zero" do
      expect(parse_date("1JAN00")).to eq("2000-01-01")
    end

    it "parses strings less than cutoff as 21st century dates" do
      expect(parse_date("08JUN04")).to eq("2004-06-08")
      expect(parse_date("31DEC14")).to eq("2014-12-31")
      expect(parse_date("31MAR49")).to eq("2049-03-31")
      expect(parse_date("31MAR85")).to eq("2085-03-31")
    end

    it "parses strings with year greater than cutoff as 20th century dates" do
      expect(parse_date("05FEB86")).to eq("1986-02-05")
      expect(parse_date("05FEB99")).to eq("1999-02-05")
    end
  end
end
