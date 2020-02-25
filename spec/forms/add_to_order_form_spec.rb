# frozen_string_literal: true

require "rails_helper"

RSpec.describe AddToOrderForm do
  include DateHelper
  let(:order) { create(:complete_order, product: product, ordered_at: 1.week.ago) }
  let(:product) { create(:setup_item, :with_facility_account) }
  subject(:form) { described_class.new(order) }

  describe "default values" do
    describe "when the order has had nothing added to it" do
      it "has order_status_id of New" do
        expect(form.order_status_id).to eq(OrderStatus.new_status.id)
      end

      it "has has the original order's account" do
        expect(form.account_id).to eq(order.account_id)
      end

      it "has other default attributes" do
        expect(form).to have_attributes(
          quantity: 1,
          fulfilled_at: be_blank,
          note: be_blank,
          reference_id: be_blank,
          product_id: be_blank,
        )
      end
    end

    describe "when there were multiple items in the original cart" do
      let(:second_order_detail) do
        create(:order_detail, order: order, ordered_at: order.order_details.first.ordered_at, product: product)
      end
      before do
        order.reload
        second_order_detail.backdate_to_complete!(10.minutes.ago)
      end

      it "has an order status of New" do
        expect(form.order_status_id).to eq(OrderStatus.new_status.id)
      end

      it "does not have a fulfilled_at" do
        expect(form.fulfilled_at).to be_blank
      end
    end

    describe "when the order has something else added to it already" do
      let(:other_account) { create(:nufs_account, :with_account_owner, owner: order.user, description: "Other Account") }
      let(:other_product) { create(:setup_item, facility: product.facility) }
      let(:second_order_detail) do
        create(:order_detail, order: order, account: other_account, product: product, note: "somenote", ordered_at: 1.day.ago)
      end

      before { order.reload }

      describe "and it is still New" do
        it "has a status of complete" do
          expect(form.order_status_id).to eq(OrderStatus.new_status.id)
        end

        it "has the second order's fulfilled_at to the matching date" do
          expect(form.fulfilled_at).to be_blank
        end

        it "still has the original order's account" do
          expect(form.account_id).to eq(order.account_id)
        end

        it "has other default attributes" do
          expect(form).to have_attributes(
            quantity: 1,
            note: be_blank,
            reference_id: be_blank,
            product_id: be_blank,
          )
        end
      end

      describe "and it is Complete" do
        before { second_order_detail.backdate_to_complete!(1.day.ago) }
        it "has a status of complete" do
          expect(form.order_status_id).to eq(OrderStatus.complete.id)
        end

        it "has the second order's fulfilled_at to the matching date" do
          expect(parse_usa_date(form.fulfilled_at)).to eq(second_order_detail.fulfilled_at.beginning_of_day)
        end
      end
    end
  end

end
