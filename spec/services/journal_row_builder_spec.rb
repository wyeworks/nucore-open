# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalRowBuilder, type: :service do

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
    let(:order_details) { order.order_details }
    let(:product) { create(:setup_item, facility: facility) }

    before do
      order_details.each(&:to_complete!)
    end

    it "builds two journal_rows for each order_detail" do
      expect(builder.build.journal_rows.size).to eq(order_details.size * 2)
    end

    it "builds a product_recharge for each order_detail" do
      expect(builder.build.product_recharges.size).to eq(order_details.size)
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
