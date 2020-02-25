# frozen_string_literal: true

require "rails_helper"
require_relative "../split_accounts_spec_helper"

RSpec.describe JournalRowBuilder, :enable_split_accounts, :default_journal_row_converters, type: :service do
  let(:builder) do
    described_class.new(journal, order_details)
  end

  let(:facility) { create(:facility) }
  let(:facility_account) { create(:facility_account, facility: facility, revenue_account: 51_234) }
  let(:product) { create(:setup_item, facility: facility, facility_account: facility_account) }
  let(:facility_account2) { create(:facility_account, facility: facility, revenue_account: 51_235) }
  let(:product2) { create(:setup_item, facility: facility, facility_account: facility_account2) }

  let(:journal) { build_stubbed(:journal, facility: facility) }
  let(:account) { build_stubbed(:split_account, splits: splits) }
  let(:user) { FactoryBot.create(:user) }
  let(:order) { create(:order, facility: facility, user: user, created_by: user.id) }
  let(:order_details) do
    [
      build_stubbed(:order_detail, actual_cost: 20.00, actual_subsidy: 0, account: account, product: product, order: order, fulfilled_at: Time.current),
      build_stubbed(:order_detail, actual_cost: 3, actual_subsidy: 0, account: account, product: product2, order: order, fulfilled_at: Time.current),
    ]
  end

  context "with a three way split" do
    let(:splits) do
      [
        build_stubbed(:split, percent: 33.33, apply_remainder: false),
        build_stubbed(:split, percent: 33.33, apply_remainder: true),
        build_stubbed(:split, percent: 33.34, apply_remainder: false),
      ]
    end

    it "comes out with 8 rows" do
      expect(builder.build.journal_rows.length).to eq(8)
    end

    it "splits the first order detail into three rows" do
      rows = builder.build.journal_rows.select { |row| row.order_detail_id == order_details.first.id }

      expect(rows.map(&:amount)).to eq([6.66, 6.68, 6.66])
    end

    it "2 negative rows for the facility accounts" do
      rows = builder.build.journal_rows.select { |row| row.account.to_i == facility_account.revenue_account }
      expect(rows.length).to eq(1)
      expect(rows.first.amount).to eq(-20)
      expect(rows.first.order_detail_id).to be_blank

      rows2 = builder.journal_rows.select { |row| row.account.to_i == facility_account2.revenue_account }
      expect(rows2.length).to eq(1)
      expect(rows2.first.amount).to eq(-3)
      expect(rows2.first.order_detail_id).to be_blank
    end
  end
end
