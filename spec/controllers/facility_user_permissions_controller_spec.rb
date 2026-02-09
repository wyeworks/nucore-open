# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityUserPermissionsController, feature_setting: { granular_permissions: true } do
  render_views

  before(:all) { create_users }

  let(:facility) { create(:facility) }
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

    it_should_allow_admin_only do
      expect(assigns(:user)).to eq(target_user)
      expect(assigns(:permission)).to be_a(FacilityUserPermission)
    end

    context "as a user with assign_permissions" do
      let(:permission_user) { create(:user) }

      before do
        create(:facility_user_permission, user: permission_user, facility:, assign_permissions: true)
        sign_in permission_user
      end

      it "allows access" do
        get :edit, params: @params
        expect(response).to be_successful
        expect(assigns(:user)).to eq(target_user)
        expect(assigns(:permission)).to be_a(FacilityUserPermission)
      end

      it "does not show the assign_permissions checkbox" do
        get :edit, params: @params
        expect(response.body).not_to include("assign_permissions")
      end
    end

    context "as a user without assign_permissions" do
      let(:no_permission_user) { create(:user) }

      before { sign_in no_permission_user }

      it "denies access" do
        expect { get :edit, params: @params }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as a user with other permissions but not assign_permissions" do
      let(:other_permission_user) { create(:user) }

      before do
        create(:facility_user_permission, user: other_permission_user, facility:, product_management: true)
        sign_in other_permission_user
      end

      it "denies access" do
        expect { get :edit, params: @params }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  context "update" do
    before :each do
      @method = :patch
      @action = :update
      @params[:facility_user_permission] = { product_management: true, billing_journals: true }
    end

    it_should_allow_admin_only :redirect do
      expect(assigns(:permission)).to be_persisted
      expect(assigns(:permission).product_management).to be true
      expect(assigns(:permission).billing_journals).to be true
      expect(assigns(:permission).order_management).to be false
    end

    context "as a global admin" do
      before { sign_in @admin }

      it "creates a log event on first save" do
        patch :update, params: @params
        permission = FacilityUserPermission.find_by(user: target_user, facility:)
        expect(LogEvent).to be_exists(loggable: permission, event_type: :create, user: @admin)
      end

      it "creates an update log event on subsequent saves" do
        create(:facility_user_permission, user: target_user, facility:)
        patch :update, params: @params
        permission = FacilityUserPermission.find_by(user: target_user, facility:)
        expect(LogEvent).to be_exists(loggable: permission, event_type: :update, user: @admin)
      end

      it "redirects to facility users path" do
        patch :update, params: @params
        expect(response).to redirect_to(facility_facility_users_path(facility))
      end

      it "can assign the assign_permissions permission" do
        @params[:facility_user_permission] = { assign_permissions: true }
        patch :update, params: @params
        permission = FacilityUserPermission.find_by(user: target_user, facility:)
        expect(permission.assign_permissions).to be true
      end
    end

    context "as a user with assign_permissions" do
      let(:permission_user) { create(:user) }

      before do
        create(:facility_user_permission, user: permission_user, facility:, assign_permissions: true)
        sign_in permission_user
      end

      it "can update permissions" do
        patch :update, params: @params
        expect(response).to redirect_to(facility_facility_users_path(facility))
        permission = FacilityUserPermission.find_by(user: target_user, facility:)
        expect(permission.product_management).to be true
        expect(permission.billing_journals).to be true
      end

      it "cannot assign the assign_permissions permission" do
        @params[:facility_user_permission] = { assign_permissions: true, product_management: true }
        patch :update, params: @params
        permission = FacilityUserPermission.find_by(user: target_user, facility:)
        expect(permission.assign_permissions).to be false
        expect(permission.product_management).to be true
      end
    end

    context "as a user without assign_permissions" do
      let(:no_permission_user) { create(:user) }

      before { sign_in no_permission_user }

      it "denies access" do
        expect { patch :update, params: @params }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  context "as a user with assign_permissions granted" do
    let(:permission_user) { create(:user) }

    before do
      create(:facility_user_permission, user: permission_user, facility:, assign_permissions: true)
      sign_in permission_user
    end

    it "allows access to edit" do
      get :edit, params: { facility_id: facility.url_name, id: target_user.id }
      expect(response).to be_successful
    end

    it "allows access to update" do
      patch :update, params: { facility_id: facility.url_name, id: target_user.id, facility_user_permission: { product_management: true } }
      expect(response).to redirect_to(facility_facility_users_path(facility))
    end

    it "allows access to search" do
      get :search, params: { facility_id: facility.url_name }
      expect(response).to be_successful
    end
  end

  context "as a user with other permissions but not assign_permissions" do
    let(:user_without_assign) { create(:user) }

    before do
      create(:facility_user_permission, user: user_without_assign, facility:, product_management: true)
      sign_in user_without_assign
    end

    it "denies access to edit" do
      expect { get :edit, params: { facility_id: facility.url_name, id: target_user.id } }.to raise_error(CanCan::AccessDenied)
    end
  end

  context "when granular_permissions feature is disabled", feature_setting: { granular_permissions: false } do
    before { sign_in @admin }

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
