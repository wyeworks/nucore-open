# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalRowBuilder, :default_journal_row_converters, type: :service do

  let(:builder) { described_class.new(journal, order_details) }
  let(:order_details) { build_stubbed_list(:order_detail, 2) }
  let(:journal) { build_stubbed(:journal) }

  describe "initialize" do

    it "assigns journal" do
      expect(builder.journal).to eq(journal)
    end

    it "assigns order_details" do
      expect(builder.order_details).to eq(order_details)
    end

    it "assigns empty errors" do
      expect(builder.errors).to eq([])
    end

    it "assigns empty journal_rows" do
      expect(builder.journal_rows).to eq([])
    end

    it "assigns empty product_recharges" do
      expect(builder.product_recharges).to eq({})
    end

  end

  describe "#build" do

    let(:journal) do
      build(:journal,
            facility: facility,
            created_by: 1,
            journal_date: journal_date,
           )
    end

    let(:facility) { create(:setup_facility) }
    let(:journal_date) { Time.zone.now }
    let(:order) { create(:purchased_order, product: product) }
    let(:order2) { create(:purchased_order, product: product) }
    let(:order_details) { order.order_details + order2.order_details }
    let(:product) { create(:setup_item, facility: facility) }

    before do
      order_details.each(&:to_complete!)
    end

    context "when using the default builders (one row per order detail, plus one recharge per product)" do

      it "builds two journal_rows for the order_detail and one for the product" do
        rows = builder.build.journal_rows
        expect(rows.size).to eq(3)
        expect(rows).to match([
          have_attributes(
            order_detail: order.order_details.first,
            amount: be_positive,
          ),
          have_attributes(
            order_detail: order2.order_details.first,
          ),
          have_attributes(
            order_detail: nil,
            amount: - (order.order_details.first.actual_cost + order2.order_details.first.actual_cost),
            description: product.name,
          ),
        ])
      end

    end

    context "when using a double entry order detail builder and a null product builder" do
      before do
        allow(Converters::ConverterFactory).to receive(:for).with("order_detail_to_journal_rows").and_return(Converters::DoubleEntryOrderDetailToJournalRowAttributes)
        allow(Converters::ConverterFactory).to receive(:for).with("product_to_journal_rows").and_return(Converters::NullProductToJournalRowAttributes)
      end

      it "builds four rows, one positive and one negative for each order detail" do
        rows = builder.build.journal_rows
        expect(rows.size).to eq(4)
        expect(rows).to match([
          having_attributes(
            order_detail: order.order_details.first,
            amount: be_positive,
            account_id: order.order_details.first.account_id,
          ),
          having_attributes(
            order_detail: nil,
            amount: -1 * order.order_details.first.actual_cost,
            account_id: nil,
            description: product.name,
          ),
          having_attributes(
            order_detail: order2.order_details.first,
            amount: be_positive,
            account_id: order2.order_details.first.account_id,
          ),
          having_attributes(
            order_detail: nil,
            amount: -1 * order2.order_details.first.actual_cost,
            account_id: nil,
            description: product.name,
          )
        ])
      end
    end

  end

  describe "#valid?" do
    context "when errors present" do
      before { allow(builder).to receive(:errors).and_return(["fake error"]) }
      it "returns true" do
        expect(builder.valid?).to eq(false)
      end
    end

    context "when errors blank" do
      before { allow(builder).to receive(:errors).and_return([]) }
      it "returns false" do
        expect(builder.valid?).to eq(true)
      end
    end
  end

  describe "#pending_facility_ids" do
    let(:fake_facility_ids) { ["fake id"] }
    it "returns pending facility ids" do
      allow(Journal).to receive(:facility_ids_with_pending_journals).and_return(fake_facility_ids)
      expect(builder.pending_facility_ids).to eq(fake_facility_ids)
    end
  end

end
