# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionSearch::Searcher, type: :service do
  describe "a basic searcher" do
    let(:item) { create(:setup_item) }
    let(:order) { create(:purchased_order, product: item) }
    let(:order_detail) { order.order_details.first }
    let(:account) { order.account }
    let(:searcher) { described_class.new(*searchers) }
    let(:searchers) do
      [
        TransactionSearch::AccountSearcher,
        TransactionSearch::DateRangeSearcher,
        TransactionSearch::AccountTypeSearcher,
      ]
    end
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

    describe "account type searching" do
      it "can search by the account type" do
        result = searcher.search(scope, account_types: [account.type])
        expect(result.order_details).to include(order_detail)
      end

      it "can search by the account type with a blank" do
        result = searcher.search(scope, account_types: ["", account.type])
        expect(result.order_details).to include(order_detail)
      end

      it "does not find it with a different account type" do
        result = searcher.search(scope, account_types: ["FakeAccountType"])
        expect(result.order_details).to be_empty
      end

      it "returns the scope when passed nil" do
        result = searcher.search(scope, account_types: nil)
        expect(result.order_details).to match_array scope
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

  describe "can toggle default searchers by key" do
    it "can disable some searcher" do
      searcher_key = described_class.default_searchers.sample.key

      searcher = described_class.new(searcher_key.to_sym => false)

      expect(searcher.instance_eval { @searchers.map(&:key) }).not_to(
        include(searcher_key)
      )
    end

    it "can enable facilities searcher" do
      searcher = described_class.new(facilities: true)

      expect(searcher.instance_eval { @searchers.map(&:key) }).to(
        include("facilities")
      )
    end

    it "disables facility searcher by default" do
      searcher = described_class.new

      expect(searcher.instance_eval { @searchers.map(&:key) }).not_to(
        include("facilities")
      )
    end
  end

end
