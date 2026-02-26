# frozen_string_literal: true

require "rails_helper"

RSpec.describe "order_management/order_details", type: :request do
  let(:facility) { create(:setup_facility) }
  let(:product) { create(:setup_service, facility:) }
  let(:order) { create(:purchased_order, product:) }
  let(:order_detail) { order.order_details.last }

  describe "mark as unrecoverable" do
    let(:params) do
      {
        order_detail: {
          id: order_detail.id,
          order_status_id: OrderStatus.unrecoverable.id
        }
      }
    end

    before do
      order_detail.change_status!(OrderStatus.complete)
      order_detail.update(statement: create(:statement))
    end

    context "as non allowed user", :disable_requests_local do
      it "does not update the status" do
        login_as(create(:user, :facility_administrator, facility:))

        put(
          manage_facility_order_order_detail_path(facility, order, order_detail),
          params:
        )

        expect(response).to have_http_status(:forbidden)
        expect(order_detail.reload.unrecoverable?).to be false
      end
    end

    context "as administrator" do
      it "changes the order detail status" do
        login_as(create(:user, :administrator))

        put(
          manage_facility_order_order_detail_path(facility, order, order_detail),
          params:
        )

        expect(response).to have_http_status(:found)
        expect(order_detail.reload.unrecoverable?).to be true
      end
    end
  end

  describe "price adjustment enforcement", feature_setting: { granular_permissions: true } do
    let(:item) { create(:setup_item, facility:) }
    let(:item_order) { create(:purchased_order, product: item) }
    let(:item_order_detail) { item_order.order_details.last }
    let(:original_cost) { 10.0 }

    before do
      item_order_detail.change_status!(OrderStatus.complete)
      item_order_detail.update_columns(actual_cost: original_cost, actual_subsidy: 0, price_change_reason: "test setup")
    end

    context "as a user with order_management only" do
      let(:order_management_user) { create(:user) }

      before do
        create(:facility_user_permission, user: order_management_user, facility:, order_management: true)
      end

      it "ignores actual_cost and actual_subsidy params" do
        login_as(order_management_user)

        put(
          manage_facility_order_order_detail_path(facility, item_order, item_order_detail),
          params: { order_detail: { actual_cost: 99.99, actual_subsidy: 5.0, price_change_reason: "price adjustment reason" } },
        )

        item_order_detail.reload
        expect(item_order_detail.actual_cost.to_f).not_to eq(99.99)
        expect(item_order_detail.actual_subsidy.to_f).not_to eq(5.0)
      end
    end

    context "as a user with price_adjustment" do
      let(:price_adjustment_user) { create(:user) }

      before do
        create(:facility_user_permission, user: price_adjustment_user, facility:, price_adjustment: true)
      end

      it "allows updating actual_cost" do
        login_as(price_adjustment_user)

        put(
          manage_facility_order_order_detail_path(facility, item_order, item_order_detail),
          params: { order_detail: { actual_cost: 99.99, price_change_reason: "price adjustment reason" } },
        )

        expect(response).to redirect_to(facility_order_path(facility, item_order))
        expect(item_order_detail.reload.actual_cost.to_f).to eq(99.99)
      end
    end

    context "as a user with both order_management and price_adjustment" do
      let(:both_permissions_user) { create(:user) }

      before do
        create(:facility_user_permission, user: both_permissions_user, facility:, order_management: true, price_adjustment: true)
      end

      it "allows updating actual_cost" do
        login_as(both_permissions_user)

        put(
          manage_facility_order_order_detail_path(facility, item_order, item_order_detail),
          params: { order_detail: { actual_cost: 55.00, price_change_reason: "price adjustment reason" } },
        )

        expect(response).to redirect_to(facility_order_path(facility, item_order))
        expect(item_order_detail.reload.actual_cost.to_f).to eq(55.00)
      end
    end
  end
end
