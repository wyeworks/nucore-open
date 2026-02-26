# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "price_policies_controller_shared_examples"

RSpec.describe InstrumentPricePoliciesController do
  render_views

  before(:all) { create_users }

  params_modifier = Class.new do
    def before_create(params)
      params.merge! charge_for: InstrumentPricePolicy::CHARGE_FOR[:reservation]
    end

    alias_method :before_update, :before_create
  end

  it_should_behave_like PricePoliciesController, :instrument, params_modifier.new

  context "with granular permissions", feature_setting: { granular_permissions: true } do
    let(:facility) { create(:setup_facility) }
    let(:instrument) { create(:instrument, facility:, no_relay: true) }
    let(:permitted_user) { create(:user) }
    let(:unpermitted_user) { create(:user) }
    let!(:price_group) { create(:price_group, facility:) }
    let!(:price_policy) { create(:instrument_price_policy, product: instrument, price_group:) }

    before do
      create(:facility_user_permission, user: permitted_user, facility:, product_pricing: true)
    end

    describe "GET #index" do
      it "allows a user with product_pricing permission" do
        sign_in permitted_user
        get :index, params: { facility_id: facility.url_name, instrument_id: instrument.url_name }
        expect(response).to be_successful
      end

      it "denies a user without product_pricing permission" do
        sign_in unpermitted_user
        expect { get :index, params: { facility_id: facility.url_name, instrument_id: instrument.url_name } }.to raise_error(CanCan::AccessDenied)
      end
    end

    describe "GET #new" do
      it "allows a user with product_pricing permission" do
        sign_in permitted_user
        get :new, params: { facility_id: facility.url_name, instrument_id: instrument.url_name }
        expect(response).to be_successful
      end

      it "denies a user without product_pricing permission" do
        sign_in unpermitted_user
        expect { get :new, params: { facility_id: facility.url_name, instrument_id: instrument.url_name } }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "with only product_management permission" do
      let(:management_user) { create(:user) }

      before do
        create(:facility_user_permission, user: management_user, facility:, product_management: true)
      end

      it "allows viewing price policies index" do
        sign_in management_user
        get :index, params: { facility_id: facility.url_name, instrument_id: instrument.url_name }
        expect(response).to be_successful
      end

      it "denies creating new price policies" do
        sign_in management_user
        expect { get :new, params: { facility_id: facility.url_name, instrument_id: instrument.url_name } }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
