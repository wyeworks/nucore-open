# frozen_string_literal: true

module Reports

  class ExportRawReportsController < CsvExportController

    MAX_REPORT_PERIOD_DAYS = 60

    include StatusFilterParams

    def export_all
      if date_range_too_large?
        flash[:error] = t(
          ".date_range_too_large",
          days: MAX_REPORT_PERIOD_DAYS,
        )

        redirect_back_or_to(success_redirect_path)
      else
        super
      end
    end

    private

    def report_class
      Reports::ExportRaw
    end

    def report_args
      {
        facility_url_name: current_facility.url_name,
        date_range_field: params[:date_range_field],
        date_start: @date_start,
        date_end: @date_end,
        order_status_ids: @status_ids,
      }
    end

    def success_redirect_path
      facility_general_reports_path(current_facility, report_by: :product)
    end

    def date_range_too_large?
      return false unless [@date_start, @date_end].all?(&:present?)

      (@date_end - @date_start) > MAX_REPORT_PERIOD_DAYS.days
    end

  end

end
