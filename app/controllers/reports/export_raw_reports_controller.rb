# frozen_string_literal: true

module Reports

  class ExportRawReportsController < CsvExportController

    include StatusFilterParams

    def self.max_period_days
      Settings.dig(:reports, :export_raw, :max_period_days) || 60
    end

    def export_all
      if date_range_too_large?
        render(
          plain: t(
            ".date_range_too_large",
            days: self.class.max_period_days,
          ),
          status: :bad_request,
        )
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

      (@date_end - @date_start) > self.class.max_period_days.days
    end

  end

end
