# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin reports" do
  let(:admin) { create(:user, :administrator) }

  context "when the feature is enabled", feature_setting: { admin_reports: true, reload_routes: true } do
    before { allow(Settings).to receive(:admin_reports).and_return(["Reports::GlobalUserRolesReport"]) }

    context "as a global administrator" do
      before { login_as admin }

      it "lists the registered reports" do
        get admin_reports_path

        expect(response.body).to include(admin_report_path("global_user_roles"))
      end

      it "queues the report email" do
        expect { get admin_report_path("global_user_roles") }
          .to have_enqueued_job(CsvReportEmailJob).with("Reports::GlobalUserRolesReport", admin.email)
        expect(response).to redirect_to(admin_reports_path)
      end

      it "responds not found for an unknown report" do
        get admin_report_path("unknown")

        expect(response).to have_http_status(:not_found)
      end
    end

    context "as an unprivileged user" do
      before { login_as create(:user) }

      it "responds forbidden" do
        get admin_reports_path

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "when the feature is disabled", feature_setting: { admin_reports: false, reload_routes: true } do
    it "does not route to the reports" do
      expect(Rails.application.routes.url_helpers).not_to respond_to(:admin_reports_path)
    end
  end
end
