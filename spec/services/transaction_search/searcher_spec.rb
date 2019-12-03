# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionSearch::Searcher, type: :service do

  describe "a basic searcher" do
    let(:item) { create(:setup_item) }
    let(:order) { create(:purchased_order, product: item) }
    let(:order_detail) { order.order_details.first }
    let(:account) { order.account }
    let(:searcher) { described_class.new(TransactionSearch::AccountSearcher, TransactionSearch::DateRangeSearcher) }
    let(:scope) { OrderDetail.all.joins(:order) }
    before do
      order_detail.to_complete!
      order_detail.update(ordered_at: 3.days.ago)
    end

    it "can find the order detail with empty params" do
      result = searcher.search(scope, {})
      expect(result.order_details).to include(order_detail)
    end

    describe "account searching" do
      it "can search by the account" do
        result = searcher.search(scope, accounts: [account.id])
        expect(result.order_details).to include(order_detail)
      end

      it "can search by the account with a blank" do
        result = searcher.search(scope, accounts: ["", account.id])
        expect(result.order_details).to include(order_detail)
      end

      it "does not find it with a different account" do
        result = searcher.search(scope, accounts: [account.id + 1])
        expect(result.order_details).to be_empty
      end
    end

    describe "date range searching" do
      it "can find the order when it has a start date before" do
        params = {
          field: "ordered_at",
          start: I18n.l(5.days.ago, format: :usa),
        }
        result = searcher.search(scope, date_ranges: params)
        expect(result.order_details).to include(order_detail)
      end

      it "does not find it when the start date is after" do
        params = {
          field: "ordered_at",
          start: I18n.l(1.day.ago.to_date, format: :usa),
        }
        result = searcher.search(scope, date_ranges: params)
        expect(result.order_details).to be_empty
      end

      it "does not find it when the start and end dates are before" do
        params = {
          field: "ordered_at",
          start: I18n.l(5.days.ago.to_date, format: :usa),
          end: I18n.l(4.days.ago.to_date, format: :usa),
        }
        result = searcher.search(scope, date_ranges: params)
        expect(result.order_details).to be_empty
      end

      it "does not find the order if searching for journaled" do
        params = {
          field: "journal_or_statement_date",
        }
        result = searcher.search(scope, date_ranges: params)
        expect(result.order_details).to be_empty
      end
    end

  end

end
