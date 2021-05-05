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

    it "saves the reconciled note to the Order Detail"  do
      expect { voucher_reconciler.reconcile_all }.to change { OrderDetail.last.reload.reconciled_note }.from(nil).to("test note")
    end
  end
end
