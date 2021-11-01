# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalRowUpdater, type: :service do
  let(:updater) { described_class.new(order_detail) }

  describe "when the order detail is on a failed journal" do
    let(:user) { FactoryBot.create(:user) }
    let(:facility) { FactoryBot.create(:setup_facility) }
    let(:account) { FactoryBot.create(:split_account, owner: user) }
    # Original costs: actual: 20, subsidy: 10
    let(:order_detail) { place_and_complete_item_order(user, facility, account, true) }
    let(:journal) { FactoryBot.create(:journal, is_successful: false, facility: facility) }
    let(:journal2) { FactoryBot.create(:journal, is_successful: false, facility: facility) }

    before do
      journal.create_journal_rows!([order_detail])
      journal2.create_journal_rows!([order_detail])
      order_detail.update(journal_id: nil)
    end

    let(:journal_rows) { journal.journal_rows.where(order_detail_id: order_detail.id) }
    let(:journal2_rows) { journal2.journal_rows.where(order_detail_id: order_detail.id) }

    describe "and I update the pricing" do
      before do
        order_detail.reload
        order_detail.update(actual_cost: 20.37)
      end

      it "updates the order detail" do
        expect(order_detail.reload.actual_cost).to eq(20.37)
        expect(order_detail.total).to eq(10.37)
      end

      it "has four journal rows" do
        expect(JournalRow.where(order_detail_id: order_detail.id).count).to eq(4)
      end

      it "has the two journal rows on different journals" do
        expect(JournalRow.where(order_detail_id: order_detail.id).map(&:journal)).to contain_exactly(journal, journal, journal2, journal2)
      end

      it "has the right accounts" do
        expect(journal_rows.map(&:account_id)).to contain_exactly(*account.subaccounts.map(&:id))
        expect(journal2_rows.map(&:account_id)).to contain_exactly(*account.subaccounts.map(&:id))
      end

      it "updates the journal rows" do
        expect(journal_rows.map(&:amount)).to contain_exactly(5.18, 5.19)
        expect(journal2_rows.map(&:amount)).to contain_exactly(5.18, 5.19)
      end
    end
  end
end
