# frozen_string_literal: true

module Reports

  class CsvExportController < ReportsController

    include CsvEmailAction

    def export_all
      queue_csv_report_email(raw_report)
    end

  end

end
