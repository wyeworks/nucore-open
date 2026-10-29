# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetails::Reconciler do
  let(:product) { create(:setup_item) }
  let(:user) { create(:user) }
  let!(:order) { create(:order, user:, created_by_user: user) }
  let(:order_details) do
    Array.new(number_of_order_details).map do
      OrderDetail.create!(product:, quantity: 1, actual_cost: 1, actual_subsidy: 0, state: "complete", statement:, order_id: order.id, created_by_user: user)
    end
  end
  let(:order_detail_attributes) { {} }
  let(:reconciler) { described_class.new(order_details:, order_detail_attributes:, reconciled_at: Time.current, order_status: "reconciled") }
  let(:account) { create(:account, :with_account_owner, type: Account.config.statement_account_types.first) }
  let(:statement) { create(:statement, facility: product.facility, account:, created_by_user: user) }

  describe "reconciling" do
    let(:number_of_order_details) { 5 }

    it "reconciles all the orders" do
      expect { reconciler.reconcile_all }.to change { OrderDetail.reconciled.count }.from(0).to(5)
    end

    context "with a bulk note" do
      context "bulk note checkbox checked" do
        let(:reconciler) do
          described_class.new(
            order_details:,
            order_detail_attributes:,
            reconciled_at: Time.current,
            order_status: "reconciled",
            bulk_reconcile: true,
            bulk_note: "this is a bulk note",
            bulk_deposit_number: "CRT1234567",
          )
        end

        it "adds the note to all order details" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq("this is a bulk note")
            expect(od.reload.deposit_number).to eq("CRT1234567")
          end
        end
      end

      context "bulk note when bulk_reconcile blank" do
        let(:reconciler) do
          described_class.new(
            order_details:,
            order_detail_attributes:,
            reconciled_at: Time.current,
            order_status: "reconciled",
            bulk_note: "this is a bulk note",
            bulk_deposit_number: "CRT1234567",
          )
        end

        it "does NOT add the note to the order details" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq(nil)
            expect(od.reload.deposit_number).to eq(nil)
          end
        end
      end
    end

    context "with NO bulk note" do
      context "with reconciled note set" do
        let(:order_detail_attributes) { order_details.to_h { |od| [od.id.to_s, { "reconciled_note" => "note #{od.id}" }] } }

        it "adds the note to the appropriate order details" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq("note #{od.id}")
          end
        end
      end

      context "with NO reconciled note set" do
        it "does not set a value" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq(nil)
            expect(od.reload.deposit_number).to eq(nil)
          end
        end
      end

      context "with previous reconciled note value, no new value set" do
        before(:each) do
          order_details.each do |od|
            od.update!(reconciled_note: "rec note #{od.id}", deposit_number: "CRT0000123")
          end
        end

        it "does not change the reconciled note" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq("rec note #{od.id}")
            expect(od.reload.deposit_number).to eq("CRT0000123")
          end
        end
      end
    end
  end

  describe "the order details to act on" do
    let(:number_of_order_details) { 3 }

    context "when given an array of order details" do
      let(:reconciler) { described_class.new(order_details: order_details.first(2), reconciled_at: Time.current) }

      it "reconciles only those order details" do
        reconciler.reconcile_all

        expect(order_details.map { |od| od.reload.state }).to eq(%w[reconciled reconciled complete])
      end
    end

    context "when given an ActiveRecord::Relation" do
      let(:reconciler) { described_class.new(order_details: OrderDetail.where(id: order_details.first(2)), reconciled_at: Time.current) }

      it "reconciles only those order details" do
        reconciler.reconcile_all

        expect(order_details.map { |od| od.reload.state }).to eq(%w[reconciled reconciled complete])
      end
    end

    context "when given a readonly relation" do
      let(:reconciler) { described_class.new(order_details: OrderDetail.where(id: order_details).readonly(true), reconciled_at: Time.current) }

      it "still saves the order details" do
        expect(reconciler.reconcile_all).to eq(3)
      end
    end

    context "when given an empty relation" do
      let(:reconciler) { described_class.new(order_details: OrderDetail.none, reconciled_at: Time.current) }

      it "reconciles nothing without erroring" do
        expect(reconciler.reconcile_all).to eq(0)
        expect(reconciler.full_errors).to be_empty
      end
    end
  end

  describe "order_detail_attributes" do
    let(:number_of_order_details) { 1 }
    let(:order_detail) { order_details.first }

    context "when keyed by string" do
      let(:order_detail_attributes) { { order_detail.id.to_s => { "reconciled_note" => "a note" } } }

      it "applies the attributes" do
        reconciler.reconcile_all

        expect(order_detail.reload.reconciled_note).to eq("a note")
      end
    end

    context "when keyed by integer" do
      let(:order_detail_attributes) { { order_detail.id => { "reconciled_note" => "a note" } } }

      it "applies the attributes" do
        reconciler.reconcile_all

        expect(order_detail.reload.reconciled_note).to eq("a note")
      end
    end

    context "when an order detail has no entry" do
      let(:order_detail_attributes) { { -1 => { "reconciled_note" => "a note" } } }

      it "reconciles it without assigning anything" do
        expect(reconciler.reconcile_all).to eq(1)
        expect(order_detail.reload.reconciled_note).to be_nil
      end
    end

    context "when given unpermitted ActionController::Parameters" do
      let(:order_detail_attributes) do
        ActionController::Parameters.new(order_detail.id.to_s => { reconciled_note: "a note" })
      end

      it "raises rather than mass-assigning" do
        expect { reconciler }.to raise_error(ActionController::UnfilteredParameters)
      end
    end
  end

  describe "marking as 'Unrecoverable'" do
    let(:reconciler) { described_class.new(order_details:, order_detail_attributes:, reconciled_at: Time.current, order_status: "unrecoverable") }
    let(:number_of_order_details) { 5 }

    it "marks all the orders as 'Unrecoverable'" do
      previous_reconciled_count = OrderDetail.reconciled.count
      previous_unrecoverable_count = OrderDetail.unrecoverable.count
      reconciler.reconcile_all
      updated_reconciled_count = OrderDetail.reconciled.count
      updated_unrecoverable_count = OrderDetail.unrecoverable.count

      expect(updated_reconciled_count).to eq(previous_reconciled_count)
      expect(updated_unrecoverable_count).to eq(previous_unrecoverable_count + 5)
    end

    context "when orders have reconciled_note" do
      let(:order_detail_attributes) do
        order_details.each_with_index.to_h { |od, idx| [od.id.to_s, { "unrecoverable_note" => "note #{idx}" }] }
      end

      it "set individual reconcile notes" do
        expect(order_details.map(&:reconciled_note).all?(nil)).to be true

        reconciler.reconcile_all

        expect(order_details.map { |od| od.reload.unrecoverable_note }.all?(String)).to be true
      end
    end

    context "when bulk_reconcile is true" do
      let(:reconciler) do
        described_class.new(
          order_details:,
          order_detail_attributes:,
          reconciled_at: Time.current,
          order_status: "unrecoverable",
          bulk_reconcile: true,
          bulk_note:,
        )
      end
      let(:bulk_note) { "Note about all orders" }

      it "set reconciled notes for all" do
        reconciler.reconcile_all

        expect(order_details.all? { |od| od.reload.unrecoverable_note == bulk_note }).to be true
      end
    end
  end

  describe "#unreconcile_all" do
    let(:order) { create(:complete_order, product:) }
    let(:order_detail) { order.order_details.first }
    let(:reconciler) { described_class.new(order_details: [order_detail], reconciled_at: nil) }

    before do
      order_detail.update!(
        fulfilled_at: 6.months.ago,
        deposit_number: "TX-1",
        reconciled_note: "Reconciled manually",
      )
      order_detail.to_reconciled!
    end

    it "moves the order detail back to complete" do
      expect(reconciler.unreconcile_all).to eq(1)

      order_detail.reload
      expect(order_detail.state).to eq("complete")
      expect(order_detail.order_status).to eq(OrderStatus.complete)
      expect(order_detail.reconciled_at).to be_nil
      expect(order_detail.deposit_number).to be_nil
      expect(order_detail.reconciled_note).to be_nil
    end

    it "does not move fulfilled_at" do
      expect { reconciler.unreconcile_all }.not_to change { order_detail.reload.fulfilled_at }
    end

    it "does not reprice the order detail" do
      expect { reconciler.unreconcile_all }.not_to change { order_detail.reload.actual_cost }
    end

    context "when the price has changed since the order was fulfilled" do
      before do
        product.price_policies.each do |price_policy|
          price_policy.update!(unit_cost: price_policy.unit_cost * 3)
        end
      end

      it "does not reprice the order detail" do
        expect { reconciler.unreconcile_all }.not_to change { order_detail.reload.actual_cost }
      end
    end

    context "when no price policy is active today" do
      before do
        product.price_policies.update_all(expire_date: 1.day.ago)
      end

      it "does not clear the cost" do
        expect { reconciler.unreconcile_all }.not_to change { order_detail.reload.actual_cost }
      end

      it "does not turn it into a problem order" do
        reconciler.unreconcile_all

        expect(order_detail.reload).not_to be_problem_order
      end
    end
  end
end
