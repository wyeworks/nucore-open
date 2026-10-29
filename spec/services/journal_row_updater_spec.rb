# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalRowUpdater, type: :service do
  let(:updater) { described_class.new(order_detail) }
  let(:order_detail) { build_stubbed(:order_detail, account:, journal_rows:) }
  let(:account) { NufsAccount.new }
  let(:journal_rows) { build_stubbed_list(:journal_row, 1) }

  describe "initialize" do
    it "assigns order_detail" do
      expect(updater.order_detail).to eq(order_detail)
    end

    it "assigns journal_rows" do
      expect(updater.journal_rows).to eq(journal_rows)
    end
  end
end
