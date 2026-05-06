# frozen_string_literal: true

require "rails_helper"

RSpec.describe "sanger_sequencing/admin/submissions" do
  let(:facility) { create(:setup_facility, sanger_sequencing_enabled: true) }

  describe "GET index" do
    let(:action) do
      proc { get facility_sanger_sequencing_admin_submissions_path(facility) }
    end

    describe "as a granular product_management user", feature_setting: { granular_permissions: true } do
      let(:user) { create(:user) }

      before do
        create(:facility_user_permission, user:, facility:, product_management: true)
        login_as user
      end

      it "is allowed to view the Sanger admin submissions index" do
        action.call

        expect(response).to have_http_status(:ok)
      end
    end

    describe "as a granular user without product_management", feature_setting: { granular_permissions: true } do
      let(:user) { create(:user) }

      before do
        create(:facility_user_permission, user:, facility:, read_access: true)
        login_as user
      end

      it "is forbidden" do
        action.call

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "as a normal user" do
      let(:user) { create(:user) }

      before { login_as user }

      it "is forbidden" do
        action.call

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "as an admin" do
      let(:admin) { create(:user, :administrator) }

      before { login_as admin }

      it "is allowed" do
        action.call

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
