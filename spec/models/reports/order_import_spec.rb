# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::OrderImport do
  let(:order_import) { OrderImport.new }
  let(:successes) { 0 }
  let(:failures) { 0 }
  let(:report_import) { described_class.new(order_import:, successes:, failures:) }

  describe "#text_content" do
    context "when successful" do
      let(:successes) { 1 }

      it "displays a success message" do
        expect(report_import.text_content).to include "The import completed successfully"
      end
    end

    it "displays a blank message if blank" do
      expect(report_import.text_content).to eq I18n.t("reports.order_import.blank")
    end

    context "when there are failures" do
      let(:successes) { 2 }
      let(:failures) { 1 }

      it "displays a failure message with the results" do
        expect(report_import.text_content).to include "The import failed. 2 line item(s) would have been created successfully, but 1 failed."
      end
    end
  end
end
