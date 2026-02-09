# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityUserPermissionsController, feature_setting: { granular_permissions: true } do
  render_views

  before(:all) { create_users }

  let(:facility) { FactoryBot.create(:facility) }
  let(:target_user) { create(:user) }

  before(:each) do
    @authable = facility
    @params = { facility_id: facility.url_name, id: target_user.id }
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
    end

    it_should_allow_managers_only do
      expect(assigns(:user)).to eq(target_user)
      expect(assigns(:permission)).to be_a(FacilityUserPermission)
    end
  end

  context "update" do
    before :each do
      @method = :patch
      @action = :update
      @params[:facility_user_permission] = { product_management: true, billing_journals: true }
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:permission)).to be_persisted
      expect(assigns(:permission).product_management).to be true
      expect(assigns(:permission).billing_journals).to be true
      expect(assigns(:permission).order_management).to be false
    end

    context "as a facility director" do
      let(:director) { create(:user, :facility_director, facility: facility) }
      before { sign_in director }

      it "creates a log event on first save" do
        patch :update, params: @params
        permission = FacilityUserPermission.find_by(user: target_user, facility: facility)
        expect(LogEvent).to be_exists(loggable: permission, event_type: :create, user: director)
      end

      it "creates an update log event on subsequent saves" do
        create(:facility_user_permission, user: target_user, facility: facility)
        patch :update, params: @params
        permission = FacilityUserPermission.find_by(user: target_user, facility: facility)
        expect(LogEvent).to be_exists(loggable: permission, event_type: :update, user: director)
      end

      it "redirects to facility users path" do
        patch :update, params: @params
        expect(response).to redirect_to(facility_facility_users_path(facility))
      end
    end
  end

  context "when granular_permissions feature is disabled", feature_setting: { granular_permissions: false } do
    let(:director) { create(:user, :facility_director, facility: facility) }
    before { sign_in director }

    it "raises a routing error on edit" do
      expect do
        get :edit, params: { facility_id: facility.url_name, id: target_user.id }
      end.to raise_error(ActionController::RoutingError)
    end

    it "raises a routing error on update" do
      expect do
        patch :update, params: { facility_id: facility.url_name, id: target_user.id, facility_user_permission: { product_management: true } }
      end.to raise_error(ActionController::RoutingError)
    end
  end
end
