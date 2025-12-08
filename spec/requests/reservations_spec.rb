# frozen_string_literal: true

require "rails_helper"

RSpec.describe "reservations" do
  describe "switch_instrument" do
    let(:facility) { create(:setup_facility) }
    let(:user) { create(:user) }
    let(:product) { create(:setup_instrument, facility:) }
    let(:reservation) do
      create(:setup_reservation, order_detail:)
    end
    let(:order_detail) { order.order_details.first }
    let(:order) do
      create(:setup_order, user:, product:, account:)
    end
    let(:account) do
      create(:setup_account).tap do |account|
        create(:account_user, :purchaser, user:, account:)
      end
    end

    describe "redirection" do
      let(:action) do
        lambda do |*args, **kwargs|
          get(
            order_order_detail_reservation_switch_instrument_path(
              order,
              order_detail,
              reservation,
              switch: "on",
            ),
            *args,
            **kwargs,
          )
        end
      end

      before do
        login_as user
      end

      context "when redirect_to is present" do
        it "redirects to internal url" do
          action.call(params: { redirect_to: reservations_path })

          expect(response.location).to eq(reservations_url)
        end

        it "does not redirect to external url" do
          action.call(
            params: { redirect_to: "https://otherdomain.com/some/path" },
          )

          expect(response.location).to(
            eq(order_order_detail_url(order, order_detail))
          )
        end
      end

      context "when referer is present" do
        it "redirects to internal url" do
          action.call(headers: { referer: reservations_path })

          expect(response.location).to eq(reservations_url)
        end

        it "does not redirect to external url" do
          referer = "https://somereferer.com/some/path"

          action.call(
            headers: { referer: "https://otherdomain.com/some/path" },
          )

          expect(response.location).to(
            eq(order_order_detail_url(order, order_detail))
          )
        end
      end

      it "falls back to order detail show url" do
        action.call

        expect(response.location).to eq(
          order_order_detail_url(order, order_detail)
        )
      end
    end
  end
end
