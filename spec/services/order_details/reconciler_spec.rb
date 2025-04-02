# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetails::Reconciler do
  let(:product) { create(:setup_item) }
  let(:user) { create(:user) }
  let!(:order) { create(:order, user: user, created_by_user: user) }
  let(:order_details) do
    Array.new(number_of_order_details).map do
      OrderDetail.create!(product: product, quantity: 1, actual_cost: 1, actual_subsidy: 0, state: "complete", statement:, order_id: order.id, created_by_user: user)
    end
  end
  let(:params) { order_details.each_with_object({}) { |od, h| h[od.id.to_s] = ActionController::Parameters.new(reconciled: "1") } }
  let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "reconciled") }
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
            OrderDetail.all,
            params,
            Time.current,
            "reconciled",
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
            OrderDetail.all,
            params,
            Time.current,
            "reconciled",
            bulk_note: "this is a bulk note",
            bulk_deposit_number: "CRT1234567"
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
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "reconciled") }
        let(:params) { order_details.each_with_object({}) { |od, h| h[od.id.to_s] = ActionController::Parameters.new(reconciled: "1", reconciled_note: "note #{od.id}") } }

        it "adds the note to the appropriate order details" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq("note #{od.id}")
          end
        end
      end

      context "with NO reconciled note set" do
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "reconciled") }

        it "does not set a value" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq(nil)
            expect(od.reload.deposit_number).to eq(nil)
          end
        end
      end

      context "with previous reconciled note value, no new value set" do
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "reconciled") }
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

  describe "marking as 'Unrecoverable'" do
    let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "unrecoverable") }
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
      before do
        params.values.each_with_index do |od_params, idx|
          od_params["unrecoverable_note"] = "note #{idx}"
        end
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
          OrderDetail.all,
          params,
          Time.current,
          "unrecoverable",
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
end
