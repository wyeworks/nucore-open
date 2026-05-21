# frozen_string_literal: true

require "rails_helper"

RSpec.describe "reservations" do
  describe "GET #index calendar events" do
    let(:facility) { create(:setup_facility) }
    let(:instrument) { create(:setup_instrument, facility:) }
    let(:path) do
      facility_instrument_reservations_path(facility, instrument, format: :json)
    end

    around do |example|
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
      ActionController::Base.allow_forgery_protection = original
    end

    it "responds with JSON to a cross-origin GET without raising" do
      expect do
        get path, params: { start: Time.current.iso8601, end: (Time.current + 1.day).iso8601 }
      end.not_to raise_error

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
    end

    it "no longer responds to the .js format" do
      get facility_instrument_reservations_path(facility, instrument, format: :js)
      expect(response).to have_http_status(:not_acceptable)
    end
  end

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
    let(:fallback_url) do
      order_order_detail_url(order, order_detail)
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

          expect(response.location).to eq(fallback_url)
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

          expect(response.location).to eq(fallback_url)
        end
      end

      it "falls back to order detail show url" do
        action.call

        expect(response.location).to eq(fallback_url)
      end
    end
  end
end
