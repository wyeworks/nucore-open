# frozen_string_literal: true

require "rails_helper"
require "controllers/shared_examples"

RSpec.describe FacilityUserReservationsController do
  let(:facility) { instrument.facility }
  let(:facility_director) { FactoryBot.create(:user, :facility_director, facility:) }
  let(:instrument) { FactoryBot.create(:setup_instrument, min_cancel_hours: 9999) }
  let(:price_policies) { instrument.price_policies }
  let(:read_access_user) { create(:user) }
  let(:user) { FactoryBot.create(:user) }

  context "GET #index" do
    let(:order_details) { reservations.map(&:order_detail) }
    let!(:reservations) do
      FactoryBot.create_list(:purchased_reservation, 3, :daily, product: instrument, user:)
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

    context "when logged in with read access", feature_setting: { granular_permissions: true } do
      let!(:permission) do
        create(:facility_user_permission, user: read_access_user, facility:, read_access: true)
      end

      def perform_request
        get :index, params: { facility_id: facility.url_name, user_id: user.id }
      end

      before(:each) { sign_in(read_access_user) }

      it "generates a page of reservations", :aggregate_failures do
        perform_request

        expect(assigns(:user)).to eq(user)
        expect(assigns(:order_details)).to match_array(order_details)
      end

      it "denies access when the permission is for another facility" do
        permission.update!(facility: create(:facility))

        expect { perform_request }.to raise_error(CanCan::AccessDenied)
      end

      it "denies access with the feature disabled", feature_setting: { granular_permissions: false } do
        expect { perform_request }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "the cancel link" do
      render_views

      let(:cancel_path) do
        cancel_facility_user_reservation_path(facility, user, order_details.first)
      end

      def perform_request
        sign_in(operator)
        get :index, params: { facility_id: facility.url_name, user_id: user.id }
      end

      context "as a facility director" do
        let(:operator) { facility_director }

        it "is rendered" do
          perform_request

          expect(response.body).to include(cancel_path)
        end
      end

      context "with only read access", feature_setting: { granular_permissions: true } do
        let(:operator) { read_access_user }

        before(:each) do
          create(:facility_user_permission, user: read_access_user, facility:, read_access: true)
        end

        it "is not rendered" do
          perform_request

          expect(response.body).not_to include(cancel_path)
        end

        it "still lists the reservations" do
          perform_request

          expect(response.body).to include(instrument.name)
        end
      end
    end
  end

  context "PUT #cancel" do
    let(:order_detail) { reservation.order_detail }
    let!(:reservation) do
      FactoryBot.create(:purchased_reservation, product: instrument, user:)
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

    context "with read access", feature_setting: { granular_permissions: true } do
      let!(:permission) do
        create(:facility_user_permission, user: read_access_user, facility:, read_access: true)
      end

      def perform_request
        put :cancel, params: {
          facility_id: facility.url_name,
          user_id: user.id,
          order_detail_id: order_detail.id,
        }
      end

      before { sign_in(read_access_user) }

      it "denies the cancellation", :aggregate_failures do
        expect { perform_request }.to raise_error(CanCan::AccessDenied)
        expect(order_detail.reload.canceled_at).to be_nil
      end
    end
  end
end
