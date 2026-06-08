# frozen_string_literal: true

require "rails_helper"

RSpec.describe "bulk email" do
  let(:facility) { create(:setup_facility) }

  describe "search" do
    let(:user) { create(:user) }
    let(:action) { -> { get facility_bulk_email_path(facility) } }

    before { login_as user }

    context "when user does not have permissions" do
      it "returns forbidden" do
        action.call

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when user has granular permissions" do
      before do
        create(:facility_user_permission, user:, facility:, bulk_email: true)
      end

      it "returns ok" do
        action.call

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user has senior staff user role" do
      before do
        user.user_roles.create!(
          role: UserRole::FACILITY_SENIOR_STAFF,
          facility:,
        )
      end

      it "returns ok" do
        action.call

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
