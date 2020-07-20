# frozen_string_literal: true

require "rails_helper"

RSpec.describe SplitAccounts::OrderDetailSplitter, type: :service do
  describe "item/service orders" do
    let(:subaccount_1) { build_stubbed(:nufs_account) }
    let(:subaccount_2) { build_stubbed(:nufs_account) }

    let(:split_account) do
      build_stubbed(:split_account).tap do |split_account|
        split_account.splits.build percent: 50, apply_remainder: true, subaccount: subaccount_1
        split_account.splits.build percent: 50, apply_remainder: false, subaccount: subaccount_2
      end
    end

    let(:order) { build_stubbed(:order) }

    let(:order_detail) do
      build_stubbed(:order_detail, created_by: build_stubbed(:user),
                                   quantity: 3,
                                   actual_cost: BigDecimal("9.99"),
                                   actual_subsidy: BigDecimal("19.99"),
                                   estimated_cost: BigDecimal("29.99"),
                                   estimated_subsidy: BigDecimal("39.99"),
                                   account: split_account,
                                   order: order,
                                   note: "this is a note")
    end

    it "can be initialized" do
      expect(described_class.new(order_detail))
    end

    describe "#split" do
      let(:results) { described_class.new(order_detail).split }

      it "returns correct number of split order details" do
        expect(results.size).to eq(split_account.splits.size)
      end

      it "dups original order detail" do
        results.each do |result|
          expect(result.product).to eq(order_detail.product)
          expect(result.created_by_user).to eq(order_detail.created_by_user)
          expect(result.note).to eq(order_detail.note)
        end
      end

      it "maintains the ID display" do
        results.each do |result|
          expect(result.to_s).to eq(order_detail.to_s)
        end
      end

      it "changes account" do
        expect(results.map(&:account)).to contain_exactly(subaccount_1, subaccount_2)
      end

      it "splits quantity" do
        expect(results.map(&:quantity)).to contain_exactly(1.5, 1.5)
      end

      it "splits actual_cost" do
        expect(results.map(&:actual_cost)).to contain_exactly(5.0, 4.99)
      end

      it "splits actual_subsidy" do
        expect(results.map(&:actual_subsidy)).to contain_exactly(10.0, 9.99)
      end

      it "splits estimated_cost" do
        expect(results.map(&:estimated_cost)).to contain_exactly(15.0, 14.99)
      end

      it "splits estimated_subsidy" do
        expect(results.map(&:estimated_subsidy)).to contain_exactly(20.0, 19.99)
      end
    end
  end

  describe "order_details with reservations" do
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

    let(:instrument) { build_stubbed(:instrument) }

    let(:order_detail) do
      build_stubbed(:order_detail, reservation: reservation,
                                   created_by: 1,
                                   quantity: 1,
                                   actual_cost: BigDecimal("9.99"),
                                   actual_subsidy: BigDecimal("19.99"),
                                   estimated_cost: BigDecimal("29.99"),
                                   estimated_subsidy: BigDecimal("39.99"),
                                   account: split_account,
                                   product: instrument)
    end

    let(:start_at) { 1.hour.ago }
    let(:reservation) do
      build_stubbed(:reservation, reserve_start_at: start_at,
                                  reserve_end_at: start_at + 30.minutes, actual_start_at: start_at,
                                  actual_end_at: start_at + 45.minutes, billable_minutes: 45)
    end
    let(:order_detail_results) { described_class.new(order_detail, split_time_data: true, reporting: true).split }
    let(:results) { order_detail_results.map(&:time_data) }

    it "splits the reservation minutes" do
      expect(results.map(&:duration_mins)).to eq([10.02, 9.99, 9.99])
    end

    it "splits the actual minutes" do
      expect(results.map(&:actual_duration_mins)).to eq([15.02, 14.99, 14.99])
    end

    it "splits the billable minutes" do
      expect(results.map(&:billable_minutes)).to eq([17, 14, 14])
    end

    it "splits the order detail's accounts" do
      expect(order_detail_results.map(&:account)).to eq([subaccount_1, subaccount_2, subaccount_3])
    end

    it "splits to order details costs" do
      expect(order_detail_results.map(&:actual_cost)).to eq([3.35, 3.32, 3.32])
    end

    it "copies the reservation start and end times" do
      expect(results.map(&:reserve_start_at)).to all(eq(start_at))
      expect(results.map(&:reserve_end_at)).to all(eq(start_at + 30.minutes))
    end

    it "copies the actual start and end times" do
      expect(results.map(&:actual_start_at)).to all(eq(start_at))
      expect(results.map(&:actual_end_at)).to all(eq(start_at + 45.minutes))
    end

    it "splits calculated cost" do
      allow(order_detail).to receive(:calculated_cost).and_return(BigDecimal("6.66"))
      expect(order_detail_results.map(&:calculated_cost)).to eq([2.24, 2.21, 2.21])
    end

    it "splits the calculated cost if it's a Float" do
      allow(order_detail).to receive(:calculated_cost).and_return(6.66)
      expect(order_detail_results.map(&:calculated_cost)).to eq([2.24, 2.21, 2.21])
    end
  end

  # Fix for #135513 - Reservations were getting deleted when Export Raw was run.
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

    let(:reservation) { create(:completed_reservation, user: user) }
    let(:order_detail) { reservation.order_detail }

    it "does not do anything to the reservation" do
      order_detail.update_attributes!(account: split_account)
      expect {
        described_class.new(order_detail, split_time_data: true).split
      }.not_to change(Reservation, :count)
      expect(reservation.reload).to be_persisted
    end
  end
end
