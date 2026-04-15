# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ExportRawReportsController do
  let(:facility) { create(:setup_facility) }
  let(:user) { create(:user, :administrator) }

  context "csv report by email" do
    let(:report_class) { Reports::ExportRaw }
    let(:action) do
      -> { get(:export_all, params: { facility_id: facility.url_name }) }
    end

    before do
      sign_in user
    end

    include_examples "csv email action"
  end

  context "date validation", :perform_enqueued_jobs do
    let(:params) do
      {
        facility_id: facility.url_name,
        date_start:,
        date_end:,
        status_filter: OrderStatus.pluck(:id),
      }
    end
    let(:date_end) { Time.current.to_date }
    let(:date_start) { date_end - report_days.days }

    before do
      sign_in user
    end

    context "when period too large" do
      let(:report_days) do
        Reports::ExportRawReportsController.max_period_days + 1
      end

      it "does not run the report" do
        expect(Reports::ExportRaw).not_to receive(:new)

        get(:export_all, params:, xhr: true)

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include("Date range can be up to")
      end
    end

    context "when period is valid" do
      let(:report_days) { 10 }

      it "runs the report" do
        expect(Reports::ExportRaw).to(
          receive(:new).and_call_original,
        )

        get(:export_all, params:, xhr: true)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("A report is being prepared")
      end
    end
  end
end
