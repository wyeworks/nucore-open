# frozen_string_literal: true

module Reports

  class AdminReportsController < GlobalSettingsController

    include CsvEmailAction

    def index
      @reports = Reports::AdminReport.all
    end

    def show
      report = Reports::AdminReport.find(params[:key])
      raise ActiveRecord::RecordNotFound unless report

      queue_csv_report_email(report.report_class, fallback_location: admin_reports_path)
    end

  end

end
