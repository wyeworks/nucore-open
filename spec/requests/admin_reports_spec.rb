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

      it "queues the relay report email" do
        allow(Settings).to receive(:admin_reports).and_return(["Reports::RelayReport"])
        get admin_reports_path

        expect(response.body).to include("Instrument Relay Data")
        expect { get admin_report_path("relay") }
          .to have_enqueued_job(CsvReportEmailJob).with("Reports::RelayReport", admin.email)
      end

      it "responds not found for an unknown report" do
        get admin_report_path("unknown")

        expect(response).to have_http_status(:not_found)
      end

      it "queues the price list report email with the selected fiscal year" do
        allow(Settings).to receive(:admin_reports).and_return(["Reports::PriceListReport"])
        year = SettingsHelper.fiscal_year_end.year - 1
        get admin_reports_path

        expect(response.body).to include("Price List")
        expect { get export_admin_report_path("price_list", fiscal_year: year.to_s) }
          .to have_enqueued_job(CsvReportEmailJob)
          .with("Reports::PriceListReport", admin.email, fiscal_year: year.to_s)
      end

      context "with a report that declares filters" do
        let(:fiscal_year) { SettingsHelper.fiscal_year_end.year - 1 }

        before do
          stub_const("Reports::FilteredTestReport", Class.new do
            def self.filters
              [:fiscal_year]
            end
          end)
          allow(Settings).to receive(:admin_reports).and_return(["Reports::FilteredTestReport"])
        end

        it "links to the report instead of queuing it from the index" do
          get admin_reports_path

          expect(response.body).to include(admin_report_path("filtered_test"))
        end

        it "renders a fiscal year select without queuing the report" do
          expect { get admin_report_path("filtered_test") }
            .not_to have_enqueued_job(CsvReportEmailJob)

          expect(response.body).to include("fiscal_year")
          expect(response.body).to include(SettingsHelper.fiscal_year_end.year.to_s)
        end

        it "passes the submitted filter through to the job" do
          expect { get export_admin_report_path("filtered_test", fiscal_year: fiscal_year.to_s) }
            .to have_enqueued_job(CsvReportEmailJob)
            .with("Reports::FilteredTestReport", admin.email, fiscal_year: fiscal_year.to_s)
        end

        it "omits a blank filter so the report applies its own default" do
          expect { get export_admin_report_path("filtered_test", fiscal_year: "") }
            .to have_enqueued_job(CsvReportEmailJob).with("Reports::FilteredTestReport", admin.email)
        end

        it "ignores params the report did not declare" do
          expect { get export_admin_report_path("filtered_test", sneaky: "1") }
            .to have_enqueued_job(CsvReportEmailJob).with("Reports::FilteredTestReport", admin.email)
        end
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
