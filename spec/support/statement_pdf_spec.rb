# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementPdf do
  let(:facility) { create(:setup_facility) }
  let(:account) { create(:nufs_account, :with_account_owner) }
  let(:user) { create(:user) }
  let(:invoice_date) { 3.days.ago.to_date }
  let(:statement) { create(:statement, facility: facility, account: account, created_by: user.id, invoice_date: invoice_date) }
  let(:pdf) { StatementPdfFactory.instance(statement) }

  describe "#filename" do
    it "uses invoice_date in filename" do
      expect(pdf.filename).to include(invoice_date.strftime("%m-%d-%Y"))
    end
  end

  describe "PDF content" do
    let(:pdf_content) { pdf.render }

    it "generates PDF content" do
      expect(pdf_content).to be_present
      expect(pdf_content).to match(/\A%PDF-1.\d+\b/)
    end
  end
end
