# frozen_string_literal: true

require "spec_helper"
require_relative "../support/matchers/csv_column_matcher"

RSpec.describe "CSV column matchers" do
  let(:single_line_report) { double("Single", to_csv: "Quantity,Cost\n1,$3.50") }
  let(:multi_line_report) { double("Multiline", to_csv: "Quantity,Cost\n2,$4.50\n4,$5.50") }

  describe "have_column" do
    describe "with nothing chained" do
      it "returns true for column presence" do
        matcher = have_column("Quantity")
        expect(matcher).to be_matches(single_line_report)
      end

      it "returns false for a missing column with the right message" do
        matcher = have_column("NOTFOUND")
        expect(matcher).not_to be_matches(single_line_report)
        expect(matcher.failure_message).to eq(%(Report did not have column with header "NOTFOUND"))
      end
    end

    describe "with_value" do
      it "matches a value" do
        matcher = have_column("Cost").with_value("$3.50")
        expect(matcher).to be_matches(single_line_report)
      end

      it "is composable" do
        matcher = have_column("Cost").with_value(an_instance_of(String))
        expect(matcher).to be_matches(single_line_report)
      end

      it "fails and gives the proper message if expectation does not match" do
        matcher = have_column("Cost").with_value("$4.50")
        expect(matcher).not_to be_matches(single_line_report)
        expect(matcher.failure_message).to eq(%(Expected report to have value(s) "$4.50" in column Cost, but got "$3.50"))
      end

      it "fails if the wrong number of lines" do
        matcher = have_column("Cost").with_value("$4.50")
        expect(matcher).not_to be_matches(multi_line_report)
        expect(matcher.failure_message).to eq(%(Expected report to have value(s) "$4.50" in column Cost, but got "$4.50, $5.50"))
      end
    end

    describe "with_values" do
      it "can take a single item and match against a single line report" do
        matcher = have_column("Cost").with_values("$3.50")
        expect(matcher).to be_matches(single_line_report)
      end

      it "can take a single item and fail against a multi line report" do
        matcher = have_column("Cost").with_values("$3.50")
        expect(matcher).not_to be_matches(multi_line_report)
        expect(matcher.failure_message).to eq(%(Expected report to have value(s) "$3.50" in column Cost, but got "$4.50, $5.50"))
      end

      it "can take an array" do
        matcher = have_column("Cost").with_values(["$4.50", "$5.50"])
        expect(matcher).to be_matches(multi_line_report)
      end

      it "can take multiple arguments" do
        matcher = have_column("Cost").with_values("$4.50", "$5.50")
        expect(matcher).to be_matches(multi_line_report)
      end

      it "is composable" do
        matcher = have_column("Cost").with_values(a_string_starting_with("$4"), /\A\$5/)
        expect(matcher).to be_matches(multi_line_report)
      end
    end
  end

  describe "have_column_values" do
    it "can match with a hash of single values" do
      matcher = have_column_values(
        "Quantity" => "1",
        "Cost" => "$3.50",
      )
      expect(matcher).to be_matches(single_line_report)
    end

    it "can match with a partial hash of arrays" do
      matcher = have_column_values(
        "Quantity" => %w[2 4],
      )
      expect(matcher).to be_matches(multi_line_report)
    end

    it "can match with a full hash of arrays" do
      matcher = have_column_values(
        "Cost" => %w[$4.50 $5.50],
        "Quantity" => %w[2 4],
      )
      expect(matcher).to be_matches(multi_line_report)
    end

    it "is composable" do
      matcher = have_column_values(
        "Cost" => [a_string_starting_with("$"), /\A\$/],
      )
      expect(matcher).to be_matches(multi_line_report)
    end

    it "has a failure message when one failure" do
      matcher = have_column_values(
        "Quantity" => "WRONG",
        "Cost" => "$3.50",
      )
      expect(matcher).not_to be_matches(single_line_report)
      expect(matcher.failure_message).to eq(%(Expected report to have value(s) "WRONG" in column Quantity, but got "1"))
    end

    it "has multiple messages when multiple failures" do
      matcher = have_column_values(
        "Quantity" => "WRONG",
        "Cost" => "$WRONGCOST",
      )
      expect(matcher).not_to be_matches(single_line_report)
      expect(matcher.failure_message).to include(%(Expected report to have value(s) "WRONG" in column Quantity, but got "1"))
      expect(matcher.failure_message).to include(%(Expected report to have value(s) "$WRONGCOST" in column Cost, but got "$3.50"))
    end
  end
end
