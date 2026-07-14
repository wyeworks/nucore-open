# frozen_string_literal: true

require "rails_helper"

RSpec.describe "order_details" do
  describe "show" do
    let(:user) { create(:user) }
    let(:account) do
      create(:setup_account).tap do |account|
        create(:account_user, :purchaser, user:, account:)
      end
    end
    let(:product) { create(:setup_item) }
    let(:facility) { product.facility }
    let(:action) do
      lambda do
        get order_order_detail_path(order, order_detail)
      end
    end

    before { login_as user }

    shared_examples "renders successfully" do
      it "includes order detail" do
        action.call

        expect(page).to have_text(order_detail.order_number)
      end

      it "renders correctly" do
        action.call

        expect(response).to have_http_status(:ok)
      end
    end

    context "when order is purchased" do
      let(:order) do
        create(:purchased_order, product:, user:, account:)
      end
      let(:order_detail) { order.order_details.first }

      it_behaves_like "renders successfully"

      it "does not show receipt link" do
        action.call

        expect(page).to have_link(
          "Receipt",
          href: receipt_order_path(order),
        )
      end
    end

    context "when ordered at is nil" do
      let(:order) do
        create(:setup_order, product:, ordered_at: nil, user:, account:)
      end
      let(:order_detail) { order.order_details.first }

      it_behaves_like "renders successfully"

      it "shows receipt link" do
        action.call

        expect(page).not_to have_link(
          "Receipt",
          href: receipt_order_path(order),
        )
      end
    end
  end

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
