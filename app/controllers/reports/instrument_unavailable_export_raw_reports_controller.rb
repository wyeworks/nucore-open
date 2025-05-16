# frozen_string_literal: true

module Reports

  class InstrumentUnavailableExportRawReportsController < CsvExportController

    private

    def report_class
      Reports::InstrumentUnavailableExportRaw
    end

    def report_args
      {
        facility: current_facility,
        date_start: @date_start,
        date_end: @date_end,
      }
    end

    def success_redirect_path
      facility_instrument_reports_path(current_facility, report_by: :instrument)
    end

  end

end
