# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statement do
  subject(:statement) { create(:statement, account: account, created_by: user.id, facility: facility) }

  let(:account) { create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user)) }
  let(:facility) { create(:facility) }
  let(:user) { create(:user) }

  context "when missing required attributes" do
    context "without created_by" do
      let(:invalid_statement) { Statement.new(created_by: nil, facility: facility) }

      it "should be invalid" do
        expect(invalid_statement).to_not be_valid
        expect(invalid_statement.errors[:created_by]).to be_present
      end
    end

    context "without facility" do
      let(:invalid_statement) { Statement.new(created_by: user.id, facility_id: nil) }

      it "should be invalid" do
        expect(invalid_statement).to_not be_valid
        expect(invalid_statement.errors[:facility_id]).to be_present
      end
    end
  end

  context "with valid attributes" do
    it "should be valid" do
      expect(statement).to be_valid
      expect(statement.errors).to be_blank
    end
  end

  context "with order details" do
    before :each do
      @order_details = []
      3.times do
        @order_details << place_and_complete_item_order(user, facility, account, true)
        # @item is set by place_and_complete_item_order, so we need to define it as open
        # for each one
        define_open_account(@item.account, account.account_number)
      end
      @order_details.each { |od| statement.add_order_detail(od) }
    end

    it "should set the statement_id of each order detail" do
      @order_details.each do |order_detail|
        expect(order_detail.statement_id).to be_present
      end
    end

    it "should have 3 order_details" do
      expect(statement.order_details.size).to eq 3
    end

    it "should have 3 rows" do
      expect(statement.statement_rows.size).to eq 3
    end

    it "should not be reconciled" do
      expect(statement).to_not be_reconciled
    end

    it "is not in the reconciled scope" do
      expect(described_class.reconciled).not_to include(statement)
    end

    it "is in the unreconciled scope" do
      expect(described_class.unreconciled).to include(statement)
    end

    context "with one order detail reconciled" do
      before :each do
        @order_details.first.to_reconciled!
      end

      it "should not be reconciled" do
        expect(statement).to_not be_reconciled
      end

      it "is not in the reconciled scope" do
        expect(Statement.reconciled).not_to include(statement)
      end

      it "is in the unreconciled scope" do
        expect(described_class.unreconciled).to include(statement)
      end
    end

    context "with all order_details reconciled" do
      before :each do
        @order_details.each(&:to_reconciled!)
      end

      it "should be reconciled" do
        expect(statement).to be_reconciled
      end

      it "is in the reconciled scope" do
        expect(described_class.reconciled).to include(statement)
      end

      it "is not in the unreconciled scope" do
        expect(described_class.unreconciled).not_to include(statement)
      end
    end

    context "#remove_order_detail" do
      it "is destroyed when it no longer has any statement_rows" do
        @order_details.each do |order_detail|
          statement.remove_order_detail(order_detail)
        end

        expect { statement.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    describe "#paid_in_full?" do
      it "is not paid_in_full with no payments" do
        expect(statement).not_to be_paid_in_full
      end

      describe "with partial payment" do
        let!(:payments) { FactoryBot.create(:payment, account: statement.account, statement: statement, amount: statement.total_cost / 2) }

        it "is not paid_in_full" do
          expect(statement).not_to be_paid_in_full
        end
      end

      describe "with multiple payments totaling to the total amount" do
        let!(:payments) { FactoryBot.create_list(:payment, 2, account: statement.account, statement: statement, amount: statement.total_cost / 2) }

        it "is paid_in_full" do
          expect(statement).to be_paid_in_full
        end
      end
    end
  end
end
