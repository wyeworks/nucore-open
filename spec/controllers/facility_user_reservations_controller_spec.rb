# frozen_string_literal: true

require "rails_helper"
require "controllers/shared_examples"

RSpec.describe FacilityUserReservationsController do
  let(:facility) { instrument.facility }
  let(:facility_director) { FactoryBot.create(:user, :facility_director, facility: facility) }
  let(:instrument) { FactoryBot.create(:setup_instrument, min_cancel_hours: 9999) }
  let(:price_policies) { instrument.price_policies }
  let(:user) { FactoryBot.create(:user) }

  context "GET #index" do
    let(:order_details) { reservations.map(&:order_detail) }
    let!(:reservations) do
      FactoryBot.create_list(:purchased_reservation, 3, :daily, product: instrument, user: user)
    end

    context "when not logged in" do
      before { get :index, params: { facility_id: facility.url_name, user_id: user.id } }

      it_behaves_like "the user must log in"
    end

    context "when logged in as a facility director" do
      before(:each) do
        sign_in(facility_director)
        get :index, params: { facility_id: facility.url_name, user_id: user.id }
      end

      it "generates a page of reservations", :aggregate_failures do
        expect(assigns(:user)).to eq(user)
        expect(assigns(:order_details)).to match_array(order_details)
      end
    end
  end

  context "PUT #cancel" do
    let(:order_detail) { reservation.order_detail }
    let!(:reservation) do
      FactoryBot.create(:purchased_reservation, product: instrument, user: user)
    end

    shared_examples_for "it can cancel the reservation" do
      def execute_cancel_request
        sign_in(operator)
        put :cancel, params: {
          facility_id: facility.url_name,
          user_id: user.id,
          order_detail_id: order_detail.id,
        }
      end

      context "when a cancellation fee applies" do
        before do
          price_policies.update_all(cancellation_cost: 12)
          execute_cancel_request
        end

        it "cancels the reservation with fee, considering the order 'complete'", :aggregate_failures do
          expect(response)
            .to redirect_to(facility_user_reservations_path(facility, user))
          expect(flash[:error]).to be_blank
          expect(flash[:notice]).to include("canceled successfully")
          expect(order_detail.reload).to be_complete
          expect(order_detail.actual_cost).to eq(12)
        end
      end

      context "when the reservation has already been canceled" do
        before do
          reservation.order_detail.update(canceled_at: 1.second.ago)
          execute_cancel_request
        end

        it "behaves as it does when initially canceled", :aggregate_failures do
          expect(response)
            .to redirect_to(facility_user_reservations_path(facility, user))
          expect(flash[:error]).to be_blank
          expect(flash[:notice]).to include("canceled successfully")
        end
      end
    end

    context "as a facility_director" do
      let(:operator) { facility_director }
      it_behaves_like "it can cancel the reservation"
    end
  end
end
