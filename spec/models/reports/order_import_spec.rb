# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::OrderImport do
  let(:order_import) { OrderImport.new }
  let(:report_import) { described_class.new(order_import) }

  describe "#text_content" do
    it "displays a success message if successful" do
      order_import.result.successes = 1
      expect(report_import.text_content).to include "The import completed successfully"
    end

    it "displays a blank message if blank" do
      expect(report_import.text_content).to eq I18n.t("reports.order_import.blank")
    end

    it "displays a failure message if there are failures" do
      order_import.result.failures = 1
      expect(report_import.text_content).to include "The import failed."
    end
  end
end
