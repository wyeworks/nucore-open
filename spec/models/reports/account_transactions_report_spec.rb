# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::AccountTransactionsReport do
  # Defined in spec/support/contexts/cross_core_context.rb
  include_context "cross core orders"

  let(:item) { create(:setup_item, facility:, name: "Item for testing & checking") }
  let(:order_detail_ids) { order_details.pluck(:id) }
  let(:report_options) { {} }

  subject(:report) { described_class.new(order_detail_ids:, **report_options) }

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
        expect(report.to_csv.lines.count).to eq(11)
      end

      it "generates headers with Cross Core Project Facility" do
        expect(report.to_csv.lines.first).to include("Cross Core Project Facility")
      end

      it "includes the order detail's cross core project facility" do
        expect(report.to_csv.lines.second).to include(cross_core_project.facility.abbreviation)
      end

      it "includes the product's name" do
        expect(report.to_csv.lines.second).to include(item.name)
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

      describe "with show_price_breakdown false" do
        let(:report_options) { { show_price_breakdown: false } }
        let(:rows) { CSV.parse(report.to_csv) }

        it "omits the price and adjustment columns, keeping the total", :aggregate_failures do
          expect(rows.first).to include(OrderDetail.human_attribute_name(:actual_total))
          expect(rows.first).not_to include(OrderDetail.human_attribute_name(:actual_cost))
          expect(rows.first).not_to include(OrderDetail.human_attribute_name(:actual_subsidy))
        end

        it "keeps every row the same width as the headers" do
          expect(rows.map(&:size).uniq).to eq([rows.first.size])
        end
      end

      describe "with show_price_breakdown defaulted" do
        it "includes the price and adjustment columns", :aggregate_failures do
          headers = CSV.parse_line(report.to_csv)

          expect(headers).to include(OrderDetail.human_attribute_name(:actual_cost))
          expect(headers).to include(OrderDetail.human_attribute_name(:actual_subsidy))
        end
      end

      describe "price group column" do
        let(:order_details) { OrderDetail.limit(1) }
        let(:order_detail) { order_details.first }
        let(:price_policy) { order_detail.product.price_policies.last }
        let(:price_group) { price_policy.price_group }
        let(:header_row) { report.to_csv.lines.first.strip }
        let(:first_row) { report.to_csv.lines.second.strip }
        let(:first_row_values) { header_row.split(",").zip(first_row.split(",")).to_h }

        it "includes the column" do
          expect(header_row).to include(OrderDetail.human_attribute_name(:price_group))
        end

        context "and the order detail does not have price policy" do
          before { order_detail.update(price_policy_id: nil) }

          it "handles orders without price policy" do
            expect(first_row_values[OrderDetail.human_attribute_name(:price_group)]).to be_nil
          end
        end

        context "and the order detail has a price group" do
          before { order_detail.update(price_policy:) }

          it "handles orders with price policy" do
            expect(first_row_values[OrderDetail.human_attribute_name(:price_group)]).to eq(price_group.name)
          end
        end
      end

      describe "excludes the order's dispute details if feature is OFF", feature_setting: { "orders.export_order_disputes": false } do
        it "generates headers without Dispute details" do
          expect(report.to_csv.lines.first).not_to include(
            OrderDetail.human_attribute_name(:dispute_at),
            OrderDetail.human_attribute_name(:dispute_reason),
            OrderDetail.human_attribute_name(:dispute_resolved_at),
            OrderDetail.human_attribute_name(:dispute_resolved_reason)
          )
        end
      end

      describe "includes the order's dispute details if feature is ON", feature_setting: { "orders.export_order_disputes": true } do
        it "generates headers with Dispute details" do
          expect(report.to_csv.lines.first).to include(
            OrderDetail.human_attribute_name(:dispute_at),
            OrderDetail.human_attribute_name(:dispute_reason),
            OrderDetail.human_attribute_name(:dispute_resolved_at),
            OrderDetail.human_attribute_name(:dispute_resolved_reason)
          )
        end
      end
    end
  end
end
