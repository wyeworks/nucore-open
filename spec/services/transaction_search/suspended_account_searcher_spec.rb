# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionSearch::Searcher, :use_test_account do
  describe "suspended accounts filter" do
    let(:facility) { create(:setup_facility) }
    let(:user) { create(:user) }
    let(:account) do
      create(:test_account, :with_account_owner, created_by: user.id)
    end
    let(:suspended_account) do
      create(
        :test_account,
        :with_account_owner,
        created_by: user.id,
        suspended_at: Time.current,
      )
    end
    let(:searcher) do
      described_class.new(facility, suspended_accounts: true)
    end
    let(:searched_order_details) do
      searcher.search(
        facility.order_details,
        suspended_accounts: suspended_accounts_param,
      ).order_details
    end

    before do
      create(
        :complete_order,
        product: create(:setup_item, facility:),
        account:,
      )
      create(
        :complete_order,
        product: create(:setup_item, facility:),
        account: suspended_account,
      )
      facility.orders.each do |order|
        order.order_details.update_all(reviewed_at: Time.current)
      end
    end

    context "when true" do
      let(:suspended_accounts_param) { "1" }

      it "returns non empty set" do
        expect(searched_order_details).not_to be_empty
      end

      it "filters out orders with suspended accounts" do
        expect(searched_order_details).not_to include(
          *suspended_account.order_details.to_a
        )
        expect(searched_order_details).to include(
          *account.order_details.to_a
        )
      end
    end

    context "when false" do
      let(:suspended_accounts_param) { "0" }

      it "returns non empty set" do
        expect(searched_order_details).not_to be_empty
      end

      it "does not filter orders" do
        expect(searched_order_details).to include(
          *facility.order_details.to_a
        )
      end
    end
  end
end
