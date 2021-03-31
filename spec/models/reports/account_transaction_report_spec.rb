# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::AccountTransactionsReport do
  subject(:report) { Reports::AccountTransactionsReport.new(order_details, report_options) }
  let(:report_options) { {} }

  describe "#to_csv" do
    context "with no order details" do
      let(:order_details) { OrderDetail.none }

      it "generates a header" do
        expect(report.to_csv.lines.count).to eq(1)
      end
    end

    context "with one order detail" do
      let!(:order_detail) { create(:purchased_reservation).order_detail }
      let(:order_details) { OrderDetail }

      it "generates an order detail line" do
        expect(report.to_csv.lines.count).to eq(2)
      end

      describe "with estimated label_key_prefix" do
        let(:report_options) { { label_key_prefix: :estimated } }

        it "generates headers with Estimated" do
          expect(report.to_csv.lines.first).to include("Estimated Price,Estimated Adjustment,Estimated Total")
        end
      end

      describe "with nil label_key_prefix" do
        it "generates headers without Estimated" do
          expect(report.to_csv.lines.first).to include("Price,Adjustment,Total")
        end
      end
    end
  end
end
