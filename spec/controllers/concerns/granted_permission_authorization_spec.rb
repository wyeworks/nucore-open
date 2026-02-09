# frozen_string_literal: true

require "rails_helper"

RSpec.describe GrantedPermissionAuthorization do
  controller(ApplicationController) do
    include GrantedPermissionAuthorization

    before_action { authorize_granted_permission!(:assign_permissions) }

    def index
      head :ok
    end
  end

  let(:facility) { create(:facility) }
  let(:user) { create(:user) }

  before do
    routes.draw { get "index" => "anonymous#index" }
    sign_in user
  end

  context "when user is a global admin" do
    let(:user) { create(:user, :administrator) }

    it "allows access" do
      get :index, params: { facility_id: facility.url_name }
      expect(response).to have_http_status(:ok)
    end
  end

  context "when user has the required permission" do
    before do
      create(:facility_user_permission, user:, facility:, assign_permissions: true)
    end

    it "allows access" do
      get :index, params: { facility_id: facility.url_name }
      expect(response).to have_http_status(:ok)
    end
  end

  context "when user has a different permission" do
    before do
      create(:facility_user_permission, user:, facility:, product_management: true)
    end

    it "raises AccessDenied" do
      expect { get :index, params: { facility_id: facility.url_name } }.to raise_error(NUCore::PermissionDenied)
    end
  end

  context "when user has no permissions" do
    it "raises AccessDenied" do
      expect { get :index, params: { facility_id: facility.url_name } }.to raise_error(NUCore::PermissionDenied)
    end
  end

  context "when user has the permission on a different facility" do
    let(:other_facility) { create(:facility) }

    before do
      create(:facility_user_permission, user:, facility: other_facility, assign_permissions: true)
    end

    it "raises AccessDenied" do
      expect { get :index, params: { facility_id: facility.url_name } }.to raise_error(NUCore::PermissionDenied)
    end
  end

  describe "#has_granted_permission?" do
    context "when user is a global admin" do
      let(:user) { create(:user, :administrator) }

      it "returns true" do
        get :index, params: { facility_id: facility.url_name }
        expect(controller.send(:has_granted_permission?, :assign_permissions)).to be true
      end
    end

    context "when user has the permission" do
      before do
        create(:facility_user_permission, user:, facility:, assign_permissions: true)
      end

      it "returns true" do
        get :index, params: { facility_id: facility.url_name }
        expect(controller.send(:has_granted_permission?, :assign_permissions)).to be true
      end
    end

    context "when user does not have the permission" do
      before do
        create(:facility_user_permission, user:, facility:, assign_permissions: true)
      end

      it "returns false" do
        get :index, params: { facility_id: facility.url_name }
        expect(controller.send(:has_granted_permission?, :product_management)).to be false
      end
    end
  end
end
