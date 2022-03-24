# frozen_string_literal: true

module Reports

  class InstrumentUnavailableReportsController < ReportsController

    helper_method(:export_csv_report_path)

    def self.reports
      @reports ||= ActiveSupport::HashWithIndifferentAccess.new(instrument_unavailable: :type)
    end

    def export_csv_report_path
      facility_instrument_unavailable_export_raw_reports_path(format: :csv)
    end

    def export_raw_visible
      true
    end

    private

    def xhr_html_template
      "reports/instrument_unavailable_reports/report_table"
    end

    def init_report_headers
      @headers = [
        text("controllers.reports/instrument_reports.instrument"),
        text("controllers.reports/instrument_reports.type"),
        text("controllers.reports/instrument_reports.category"),
        text("controllers.reports/instrument_reports.quantity"),
        text("controllers.reports/instrument_reports.reserved"),
      ]
    end

    def init_report
      @rows = page_report(reporter.rows)
      @totals = ["", "", reporter.total_quantity, reporter.total_hours]
      @numeric_columns = reporter.numeric_columns
      @label_columns = @headers.length
    end

    def reporter
      @reporter ||=
        InstrumentUnavailableReport.new(current_facility, @date_start, @date_end)
    end

  end

end
