# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatementPdfDownloader do
  let(:account) { create(:nufs_account, :with_account_owner) }
  let(:facility) { create(:facility) }
  let(:facility_account) { create(:facility_account, facility: facility) }
  let(:user) { account.owner_user }
  # Use a stub for item/product to avoid facility_account validation issues
  let(:item) { double("Item", id: 1, facility: facility) }
  let(:order) { create(:order, facility: facility, account: account, user: user, created_by: user.id) }
  let(:order_detail) { double("OrderDetail", id: 1, order: order, product: item, account: account) }
  let(:statement1) { create(:statement, facility: facility, account: account, created_by: user.id, created_at: 1.day.ago) }
  let(:statement2) { create(:statement, facility: facility, account: account, created_by: user.id, created_at: 2.days.ago) }
  let(:statement_pdf) { double(filename: "statement.pdf", render: "pdf_data") }
  let(:controller_mock) { double("Controller") }

  before do
    allow(statement1).to receive(:order_details).and_return([order_detail])
    allow(statement2).to receive(:order_details).and_return([order_detail])
    allow(StatementPdfFactory).to receive(:instance).and_return(statement_pdf)
  end

  describe "#download_all" do
    let(:statements) { [statement1, statement2] }
    let(:downloader) { described_class.new(statements) }
    subject(:pdfs) { downloader.download_all }

    before do
      # Simulate a failure for the first statement and success for the second
      allow(StatementPdfFactory).to receive(:instance).with(statement1, download: true).and_raise("Error")
      allow(StatementPdfFactory).to receive(:instance).with(statement2, download: true).and_return(statement_pdf)
    end

    it "skips failures and returns only successful pdfs" do
      expect(pdfs).to contain_exactly(
        { filename: "statement.pdf", data: "pdf_data" }
      )
    end
  end

  describe "#handle_download_response" do
    let(:statements) { [statement1, statement2] }
    let(:downloader) { described_class.new(statements) }
    let(:fallback_path) { "/path/to/fallback" }

    before do
      allow(controller_mock).to receive(:request).and_return(double(format: :html))
      format_mock = double("format")
      allow(format_mock).to receive(:html).and_yield
      allow(format_mock).to receive(:json).and_yield
      allow(controller_mock).to receive(:respond_to).and_yield(format_mock)
      allow(controller_mock).to receive(:instance_variable_set)
      allow(controller_mock).to receive(:flash).and_return({})
      allow(controller_mock).to receive(:redirect_back)
      allow(controller_mock).to receive(:send_data)
      allow(controller_mock).to receive(:render)
    end

    context "with a single PDF" do
      let(:statements) { [statement1] }

      it "sends the PDF directly" do
        allow(controller_mock).to receive(:request).and_return(double(format: :html))
        expect(controller_mock).to receive(:send_data).with("pdf_data", hash_including(filename: "statement.pdf", type: "application/pdf"))
        expect(downloader.handle_download_response(controller_mock, fallback_path)).to be true
      end
    end

    context "with multiple PDFs" do
      it "sets pdfs instance variable" do
        expect(controller_mock).to receive(:instance_variable_set).with(:@pdfs, kind_of(Array))
        downloader.handle_download_response(controller_mock, fallback_path)
      end

      it "redirects back for HTML format" do
        expect(controller_mock).to receive(:flash).and_return({})
        expect(controller_mock).to receive(:redirect_back).with(fallback_location: fallback_path)

        downloader.handle_download_response(controller_mock, fallback_path)
      end

      it "renders JSON for JSON format" do
        allow(controller_mock).to receive(:request).and_return(double(format: :json))
        expect(controller_mock).to receive(:render).with(json: { pdfs: kind_of(Array) })

        downloader.handle_download_response(controller_mock, fallback_path)
      end
    end
  end
end
