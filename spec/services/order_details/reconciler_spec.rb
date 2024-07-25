# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetails::Reconciler do
  let(:product) { create(:setup_item) }
  let(:user) { create(:user) }
  let!(:order) { create(:order, user: user, created_by_user: user) }
  let(:order_details) do
    Array.new(number_of_order_details).map do
      OrderDetail.create!(product: product, quantity: 1, actual_cost: 1, actual_subsidy: 0, state: "complete", journal: journal, order_id: order.id, created_by_user: user)
    end
  end
  let(:params) { order_details.each_with_object({}) { |od, h| h[od.id.to_s] = ActionController::Parameters.new(reconciled: "1") } }
  let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current) }
  let(:journal) { create(:journal, facility: product.facility) }

  describe "reconciling" do
    let(:number_of_order_details) { 5 }

    it "reconciles all the orders" do
      expect { reconciler.reconcile_all }.to change { OrderDetail.reconciled.count }.from(0).to(5)
    end

    context "with a bulk note" do
      context "bulk note checkbox checked" do
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "this is a bulk note", "CRT1234567", "1") }

        it "adds the note to all order details" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq("this is a bulk note")
            expect(od.reload.deposit_number).to eq("CRT1234567")
          end
        end
      end

      context "bulk note checkbox UNchecked" do
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "this is a bulk note", "CRT1234567") }

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
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "" ) }
        let(:params) { order_details.each_with_object({}) { |od, h| h[od.id.to_s] = ActionController::Parameters.new(reconciled: "1", reconciled_note: "note #{od.id}") } }

        it "adds the note to the appropriate order details" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq("note #{od.id}")
          end
        end
      end

      context "with NO reconciled note set" do
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "", "" ) }

        it "does not set a value" do
          reconciler.reconcile_all
          order_details.each do |od|
            expect(od.reload.reconciled_note).to eq(nil)
            expect(od.reload.deposit_number).to eq(nil)
          end
        end
      end

      context "with previous reconciled note value, no new value set" do
        let(:reconciler) { described_class.new(OrderDetail.all, params, Time.current, "", "" ) }
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

  # describe "reconciling more than 1000 order details (because of oracle)" do
  #   let(:number_of_order_details) { 1001 }

  #   it "reconciles all the orders" do
  #     expect { reconciler.reconcile_all }.to change { OrderDetail.reconciled.count }.from(0).to(1001)
  #   end
  # end
end
