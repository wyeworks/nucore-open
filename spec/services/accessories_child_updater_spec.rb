# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accessories::ChildUpdater do
  let(:order) { Order.new }
  let(:order_detail) do
    build_stubbed :order_detail,
                  order: order,
                  child_order_details: [],
                  attributes: {
                    order_id: order.id,
                  }
  end

  describe "update_children" do
    let(:child_order_detail) { build(:order_detail, order: order) }
    before { allow(order_detail).to receive(:child_order_details).and_return [child_order_detail] }

    it "updates the child" do
      expect(child_order_detail).to receive(:account=)
      expect(child_order_detail).to receive(:save)
      expect(order_detail.update_children).to eq([child_order_detail])
    end
  end

  describe "updating children save hooks" do
    let(:reservation) { create :purchased_reservation }
    let(:order_detail) { reservation.order_detail }
    let(:order) { order_detail.order }
    let(:product) { create :setup_item, facility: order_detail.facility }
    let(:user) { reservation.user }
    let!(:child_order_detail) do
      order_detail
        .child_order_details
        .create(attributes_for(:order_detail, order_status: OrderStatus.new_status, product: product, order: order))
    end

    context "when accessory_independent_order_status feature is enabled", feature_setting: { accessory_independent_order_status: true } do
      context "when the parent moves from new to in process" do
        before do
          order_detail.update_order_status! user, OrderStatus.in_process
        end

        it "does not change the child's status (accessories are independent)" do
          expect(child_order_detail.reload.order_status).to eq(OrderStatus.new_status)
        end
      end

      context "when the parent moves from new to complete" do
        before do
          reservation.end_reservation!
        end

        it "does not change the child's status (accessories are independent)" do
          expect(child_order_detail.reload.order_status).to eq(OrderStatus.new_status)
        end
      end

      context "when the parent moves from complete to canceled" do
        before do
          allow_any_instance_of(Reservation).to receive(:can_cancel?).and_return true
          reservation.end_reservation!
          order_detail.update_order_status! user, OrderStatus.canceled
        end

        it "does not change the child's status (accessories are independent)" do
          expect(child_order_detail.reload.order_status).to eq(OrderStatus.new_status)
        end
      end

      context "when the child has been manually canceled" do
        before do
          child_order_detail.update_order_status! user, OrderStatus.canceled
          reservation.end_reservation!
        end

        it "keeps the child canceled" do
          expect(child_order_detail.reload).to be_canceled
        end
      end

      context "when the child has a different initial order status than the parent" do
        let(:in_process_status) { OrderStatus.in_process }

        before do
          product.update!(initial_order_status: in_process_status)
          child_order_detail.update!(order_status: in_process_status)
        end

        context "when the parent moves from new to complete" do
          before do
            reservation.end_reservation!
          end

          it "does not change the child's status" do
            expect(child_order_detail.reload.order_status).to eq(in_process_status)
          end
        end
      end
    end

    context "when accessory_independent_order_status feature is disabled (legacy behavior)", feature_setting: { accessory_independent_order_status: false } do
      context "when the parent moves from new to in process" do
        before do
          order_detail.update_order_status! user, OrderStatus.in_process
        end

        it "changes the child's status to match the parent" do
          expect(child_order_detail.reload.order_status).to eq(OrderStatus.in_process)
        end
      end

      context "when the parent moves from new to complete" do
        before do
          reservation.end_reservation!
        end

        it "changes the child's status to complete" do
          expect(child_order_detail.reload.order_status).to eq(OrderStatus.complete)
        end
      end

      context "when the child has been manually canceled" do
        before do
          child_order_detail.update_order_status! user, OrderStatus.canceled
          reservation.end_reservation!
        end

        it "keeps the child canceled (different status from parent)" do
          expect(child_order_detail.reload).to be_canceled
        end
      end

      context "when the child has a different status than the parent" do
        let(:in_process_status) { OrderStatus.in_process }

        before do
          product.update!(initial_order_status: in_process_status)
          child_order_detail.update!(order_status: in_process_status)
        end

        context "when the parent moves from new to complete" do
          before do
            reservation.end_reservation!
          end

          it "does not change the child's status (different from parent's previous status)" do
            expect(child_order_detail.reload.order_status).to eq(in_process_status)
          end
        end
      end
    end
  end
end
