# frozen_string_literal: true

require "rails_helper"

RSpec.describe "reports controller" do
  let!(:facility) { create(:setup_facility) }

  describe "index" do
    let(:user) { create(:user) }
    let(:facility_user_permission) do
      user.facility_user_permissions.find_by(facility:)
    end
    let(:action) do
      lambda do
        get facility_general_reports_path(facility, report_by: :product)
      end
    end

    before do
      user.facility_user_permissions.create(facility:, read_access: true)

      login_as user
    end

    context "when user has access" do
      before do
        facility_user_permission.update(reporting: true)
      end

      it "can see report" do
        action.call

        expect(response).to have_http_status(:ok)
        expect(page).to have_css("form.reports-form")
      end
    end

    context "when user does not have reporting access" do
      it "cannot access reports" do
        action.call

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
