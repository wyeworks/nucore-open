# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::VoucherReconciler do
  let(:product) { create(:setup_item) }
  let(:user) { create(:user) }
  let!(:order) { create(:order, user: user, created_by_user: user) }
  let(:order_details) do
    Array.new(number_of_order_details).map do
      OrderDetail.create!(product: product, quantity: 1, actual_cost: 1, actual_subsidy: 0, state: "complete", journal: journal, order_id: order.id, created_by_user: user)
    end
  end
  let!(:params) { order_details.each_with_object({}) { |od, h| h[od.id.to_s] = ActionController::Parameters.new(mivp_pending: "1", reconciled_note: "test note") } }
  let(:voucher_reconciler) { described_class.new(OrderDetail.all, params) }
  let(:journal) { create(:journal, facility: product.facility) }
  let(:mivp) { UmassCorum::VoucherOrderStatus.mivp }

  describe "marking MIVP Pending" do
    let(:number_of_order_details) { 5 }

    it "doesn't reconcile the order details" do
      expect { voucher_reconciler.reconcile_all }.not_to change { OrderDetail.reconciled.count }
    end

    it "marks all the order details MIVP Pending" do
      expect { voucher_reconciler.reconcile_all }.to change { mivp.order_details.count }.from(0).to(5)
    end
  end

  describe "#add_all_order_details_to_params" do
    let(:number_of_order_details) { 5 }

    it "adds all other details to params" do
      order_detail_id_to_add = order_details.last.id.to_s
      order_detail_param = params.extract!(order_detail_id_to_add)

      # Clear the reconciled_note value so we can use this to model expected state
      # as if this order detail was not in params from the front end
      order_detail_param[order_detail_id_to_add]["reconciled_note"] = ""

      # Make sure the order detail is not initially included in params
      expect(params[order_detail_param.keys.first]).to be_nil

      described_class.add_all_order_details_to_params(order_details, params, "mivp_pending")

      expect(params[order_detail_id_to_add]).to eq order_detail_param[order_detail_id_to_add]
    end
  end

  context "when a bulk note is used for selected orders" do
    let(:number_of_order_details) { 5 }

    context "bulk note checkbox checked" do
      let(:voucher_reconciler) { described_class.new(OrderDetail.all, params, "this is the bulk note", "1") }

      it "changes all selected orders to have the bulk note" do
        expect { voucher_reconciler.reconcile_all }.to change { OrderDetail.pluck(:reconciled_note).uniq }.from([nil]).to(["this is the bulk note"])
      end
    end

    context "bulk note checkbox unchecked" do
      let(:voucher_reconciler) { described_class.new(OrderDetail.all, params, "this is the bulk note", "0") }

      it "does not change all selected orders to have the bulk note" do
        expect { voucher_reconciler.reconcile_all }.to change { OrderDetail.pluck(:reconciled_note).uniq }.from([nil]).to(["test note"])
      end
    end
  end
end
