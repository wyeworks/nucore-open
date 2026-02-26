# frozen_string_literal: true

require "rails_helper"

RSpec.describe InstrumentRelaysController do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument, facility:, no_relay: true) }

  context "with granular permissions", feature_setting: { granular_permissions: true } do
    describe "authorization for write actions" do
      let(:product_management_user) { create(:user) }
      let(:product_pricing_user) { create(:user) }
      let(:billing_send_user) { create(:user) }

      before do
        create(:facility_user_permission, user: product_management_user, facility:, product_management: true)
        create(:facility_user_permission, user: product_pricing_user, facility:, product_pricing: true)
        create(:facility_user_permission, user: billing_send_user, facility:, billing_send: true)
      end

      describe "GET #new" do
        it "allows a user with product_management permission" do
          sign_in product_management_user
          get :new, params: { facility_id: facility.url_name, instrument_id: instrument.url_name }
          expect(response).to be_successful
        end

        it "denies a user with only product_pricing permission" do
          sign_in product_pricing_user
          expect { get :new, params: { facility_id: facility.url_name, instrument_id: instrument.url_name } }.to raise_error(CanCan::AccessDenied)
        end

        it "denies a user with only billing_send permission" do
          sign_in billing_send_user
          expect { get :new, params: { facility_id: facility.url_name, instrument_id: instrument.url_name } }.to raise_error(CanCan::AccessDenied)
        end
      end

      describe "GET #index" do
        it "allows a user with any granular permission to view" do
          sign_in billing_send_user
          get :index, params: { facility_id: facility.url_name, instrument_id: instrument.url_name }
          expect(response).to be_successful
        end
      end
    end
  end
end
