# frozen_string_literal: true

require "rails_helper"

RSpec.describe "order_details" do
  describe "cancel" do
    let(:product) { create(:setup_instrument) }
    let(:facility) { product.facility }
    let(:user) { create(:user) }
    let(:reservation) do
      create(:purchased_reservation, product:, user:)
    end
    let(:order_detail) { reservation.order_detail }
    let(:order) { order_detail.order }

    let(:action) do
      lambda do
        put cancel_order_order_detail_path(order, order_detail)
      end
    end

    before { login_as(user) }

    it "calls slot available service" do
      expect(ProductNotifications::SlotAvailableService).to(
        receive(:new).and_call_original
      )

      action.call
    end

    context "when already canceled" do
      before do
        order_detail.cancel_reservation(user)
      end

      it "does not call slot available service" do
        expect(ProductNotifications::SlotAvailableService).not_to(
          receive(:new).and_call_original
        )

        action.call
      end
    end
  end
end
