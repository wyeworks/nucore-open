# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionSearch::DateRangeSearcher do
  include DateHelper

  let(:item) { create(:setup_item) }
  let(:orders) { create_list(:purchased_order, 2, product: item) }
  let(:order_details) { orders.flat_map(&:order_details) }
  let(:searcher) { described_class.new(OrderDetail.all.joins(:order)) }

  describe "ordered_at" do
    before do
      order_details[0].update!(ordered_at: 2.days.ago)
      order_details[1].update!(ordered_at: 1.day.ago)
    end

    it "finds only the right ones when starting a day ago" do
      results = searcher.search(field: :ordered_at, start: format_usa_date(1.day.ago))
      expect(results).to eq([order_details.last])
    end

    it "finds only the right one when ending a day ago" do
      results = searcher.search(field: :ordered_at, end: format_usa_date(2.days.ago))
      expect(results).to eq([order_details.first])
    end

    it "finds nothing with an outside range" do
      results = searcher.search(field: :ordered_at, start: format_usa_date(5.days.ago), end: format_usa_date(3.days.ago))
      expect(results).to be_empty
    end

    it "finds all with a wide range in the ordered_at reverse chronological order" do
      results = searcher.search(field: :ordered_at, start: format_usa_date(5.days.ago), end: format_usa_date(1.day.from_now))
      expect(results).to eq(order_details.reverse)
    end
  end

  describe "fulfilled_at" do
    before do
      order_details[0].update!(fulfilled_at: 2.days.ago)
      order_details[1].update!(fulfilled_at: 1.day.ago)
    end

    it "finds only the right ones when starting a day ago" do
      results = searcher.search(field: :fulfilled_at, start: format_usa_date(1.day.ago))
      expect(results).to eq([order_details.last])
    end

    it "finds only the right one when ending a day ago" do
      results = searcher.search(field: :fulfilled_at, end: format_usa_date(2.days.ago))
      expect(results).to eq([order_details.first])
    end

    it "finds nothing with an outside range" do
      results = searcher.search(field: :fulfilled_at, start: format_usa_date(5.days.ago), end: format_usa_date(3.days.ago))
      expect(results).to be_empty
    end

    it "finds all with a wide range in the fulfilled_at reverse chronological order" do
      results = searcher.search(field: :fulfilled_at, start: format_usa_date(5.days.ago), end: format_usa_date(1.day.from_now))
      expect(results).to eq(order_details.reverse)
    end
  end

  describe "journal_or_statement_date" do
    describe "journaled" do
      before do
        order_details[0].update!(journal: create(:journal, journal_date: 2.days.ago))
        order_details[1].update!(journal: create(:journal, journal_date: 1.day.ago))
      end

      it "finds only the right ones when starting a day ago" do
        results = searcher.search(field: :journal_or_statement_date, start: format_usa_date(1.day.ago))
        expect(results).to eq([order_details.last])
      end

      it "finds only the right one when ending a day ago" do
        results = searcher.search(field: :journal_or_statement_date, end: format_usa_date(2.days.ago))
        expect(results).to eq([order_details.first])
      end

      it "finds nothing with an outside range" do
        results = searcher.search(field: :journal_or_statement_date, start: format_usa_date(5.days.ago), end: format_usa_date(3.days.ago))
        expect(results).to be_empty
      end

      it "finds all with a wide range in the reverse chronological order" do
        results = searcher.search(field: :journal_or_statement_date, start: format_usa_date(5.days.ago), end: format_usa_date(1.day.from_now))
        expect(results).to eq(order_details.reverse)
      end
    end

    describe "statemented" do
      before do
        order_details[0].update!(statement: create(:statement, created_at: 2.days.ago))
        order_details[1].update!(statement: create(:statement, created_at: 1.day.ago))
      end

      it "finds only the right ones when starting a day ago" do
        results = searcher.search(field: :journal_or_statement_date, start: format_usa_date(1.day.ago))
        expect(results).to eq([order_details.last])
      end

      it "finds only the right one when ending a day ago" do
        results = searcher.search(field: :journal_or_statement_date, end: format_usa_date(2.days.ago))
        expect(results).to eq([order_details.first])
      end

      it "finds nothing with an outside range" do
        results = searcher.search(field: :journal_or_statement_date, start: format_usa_date(5.days.ago), end: format_usa_date(3.days.ago))
        expect(results).to be_empty
      end

      it "finds all with a wide range in the reverse chronological order" do
        results = searcher.search(field: :journal_or_statement_date, start: format_usa_date(5.days.ago), end: format_usa_date(1.day.from_now))
        expect(results).to eq(order_details.reverse)
      end
    end
  end

  describe "reconciled_at" do
    before do
      order_details[0].update!(reconciled_at: 2.days.ago)
      order_details[1].update!(reconciled_at: 1.day.ago)
    end

    it "finds only the right ones when starting a day ago" do
      results = searcher.search(field: :reconciled_at, start: format_usa_date(1.day.ago))
      expect(results).to eq([order_details.last])
    end

    it "finds only the right one when ending a day ago" do
      results = searcher.search(field: :reconciled_at, end: format_usa_date(2.days.ago))
      expect(results).to eq([order_details.first])
    end

    it "finds nothing with an outside range" do
      results = searcher.search(field: :reconciled_at, start: format_usa_date(5.days.ago), end: format_usa_date(3.days.ago))
      expect(results).to be_empty
    end

    it "finds all with a wide range in the reconciled_at reverse chronological order" do
      results = searcher.search(field: :reconciled_at, start: format_usa_date(5.days.ago), end: format_usa_date(1.day.from_now))
      expect(results).to eq(order_details.reverse)
    end
  end
end
