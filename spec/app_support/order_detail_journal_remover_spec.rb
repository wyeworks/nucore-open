# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetailJournalRemover do
  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_item, facility:) }
  let(:orders) { create_list(:purchased_order, 2, product:) }
  let(:order_details) { orders.map { |o| o.order_details.first } }
  let(:journal) { create(:journal, facility:, updated_by: 1, reference: "xyz") }

  before :each do
    order_details.each do |order_detail|
      order_detail.journal = journal
      create(:journal_row, journal:, order_detail:)
      order_detail.save!
    end
  end

  describe ".remove_from_journal" do
    let(:order_detail) { order_details.first }

    describe "only on one journal" do
      before { described_class.remove_from_journal(order_detail) }

      it "removes order detail" do
        expect(journal.reload.order_details).not_to include(order_detail)
        expect(order_detail.journal_id).to be_nil
      end

      it "does not remove the other order detail" do
        expect(journal.reload.order_details).to include(order_details.last)
      end
    end

    describe "and the order detail was part of a previous journal" do
      let(:old_journal) do
        create(:journal, facility:, updated_by: 1,
                         reference: "xyz", is_successful: false)
      end

      before do
        order_details.each do |order_detail|
          create(:journal_row, journal: old_journal, order_detail:)
        end

        described_class.remove_from_journal(order_detail)
      end

      it "does not remove it from the old journal" do
        expect(old_journal.reload.order_details).to contain_exactly(*order_details)
      end
    end
  end
end
