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
end
