# frozen_string_literal: true

require "rails_helper"

RSpec.describe SplitAccounts::OrderDetailSplitter do
  describe "order_details with occupancies" do
    let(:subaccount_1) { build_stubbed(:nufs_account) }
    let(:subaccount_2) { build_stubbed(:nufs_account) }
    let(:subaccount_3) { build_stubbed(:nufs_account) }

    let(:split_account) do
      build_stubbed(:split_account).tap do |split_account|
        split_account.splits.build percent: 33.34, apply_remainder: true, subaccount: subaccount_1
        split_account.splits.build percent: 33.33, apply_remainder: false, subaccount: subaccount_2
        split_account.splits.build percent: 33.33, apply_remainder: false, subaccount: subaccount_3
      end
    end

    let(:secure_room) { build_stubbed(:secure_room) }

    let(:order_detail) do
      build_stubbed(:order_detail, occupancy:,
                                   created_by: 1,
                                   quantity: 1,
                                   actual_cost: BigDecimal("9.99"),
                                   actual_subsidy: BigDecimal("19.99"),
                                   estimated_cost: BigDecimal("29.99"),
                                   estimated_subsidy: BigDecimal("39.99"),
                                   account: split_account,
                                   product: secure_room)
    end

    let(:entry_at) { 1.hour.ago }
    let(:occupancy) do
      build_stubbed(:occupancy, entry_at:, exit_at: entry_at + 45.minutes)
    end
    let(:order_detail_results) { described_class.new(order_detail, split_time_data: true).split }
    let(:results) { order_detail_results.map(&:time_data) }

    it "splits the actual minutes" do
      expect(results.map(&:actual_duration_mins)).to eq([15.02, 14.99, 14.99])
    end

    it "splits the order detail's accounts" do
      expect(order_detail_results.map(&:account)).to eq([subaccount_1, subaccount_2, subaccount_3])
    end

    it "splits to order details costs" do
      expect(order_detail_results.map(&:actual_cost)).to eq([3.35, 3.32, 3.32])
    end

    it "copies the actual start and end times" do
      expect(results.map(&:actual_start_at)).to all(eq(entry_at))
      expect(results.map(&:actual_end_at)).to all(eq(entry_at + 45.minutes))
    end
  end

  describe "a real order detail" do
    let(:user) { create(:user) }
    let(:subaccount_1) { create(:nufs_account, :with_account_owner, owner: user) }
    let(:subaccount_2) { create(:nufs_account, :with_account_owner, owner: user) }

    let(:split_account) do
      create(:split_account, owner: user).tap do |split_account|
        split_account.splits.create percent: 50, apply_remainder: true, subaccount: subaccount_1
        split_account.splits.create percent: 50, apply_remainder: false, subaccount: subaccount_2
      end
    end

    let(:occupancy) { create(:occupancy, :complete, :with_order_detail, user:, account: split_account) }
    let(:order_detail) { occupancy.order_detail }

    before do
      create(:account_price_group_member, account: split_account, price_group: PriceGroup.base)
    end

    it "does not do anything to the occupancy" do
      order_detail.update!(account: split_account)
      described_class.new(order_detail, split_time_data: true).split
      expect(occupancy.reload).to be_persisted
    end
  end
end
