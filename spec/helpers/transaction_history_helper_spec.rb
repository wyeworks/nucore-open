# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionHistoryHelper do
  describe "#chosen_field"

  describe "#order_statuses_options" do
    let(:facility) { create(:facility) }
    let(:option_nodes) { parsed_result.search("option") }
    let(:parsed_result) { Nokogiri::HTML(result) }
    let(:result) { order_statuses_options(order_statuses, search_fields) }
    let(:search_fields) { nil }

    context "when given order_statuses" do
      let(:order_statuses) { create_list(:order_status, 3, facility:) }

      it { expect(parsed_result.errors).to be_blank }
      it { expect(option_nodes.count).to eq(order_statuses.count) }

      it "sets attributes" do
        order_statuses.each_with_index do |order_status, index|
          node = option_nodes[index]
          expect(node.inner_text).to eq(order_status.to_s)
          expect(node.attribute("value").value).to eq(order_status.id.to_s)
          expect(node.attribute("data-facility").value).to eq(facility.id.to_s)
        end
      end

      context "when given search_fields" do
        let(:search_fields) { order_statuses.map(&:id) }

        it "sets options as selected" do
          order_statuses.each_with_index do |_order_status, index|
            expect(option_nodes[index].attribute("selected")).to be_present
          end
        end
      end
    end

    context "when given no order_statuses" do
      let(:order_statuses) { [] }

      it "returns no options" do
        expect(result).to eq("")
      end
    end
  end

  describe "#product_options"

  describe "#row_class"
end
