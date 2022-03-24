# frozen_string_literal: true

module Reports

  class InstrumentReportsController < ReportsController

    helper_method(:export_csv_report_path)

    include InstrumentReporter

    def self.reports
      @reports ||= ActiveSupport::HashWithIndifferentAccess.new(
        instrument: nil,
        account: ->(reservation) { reservation.order_detail.account },
        account_owner: ->(reservation) { format_username(reservation.order_detail.account.owner_user) },
        purchaser: ->(reservation) { format_username(reservation.order_detail.user) },
      )
    end

    def export_csv_report_path
      facility_instrument_unavailable_export_raw_reports_path(format: :csv)
    end

    def export_raw_visible?
      false
    end

    private

    def init_report_headers
      @headers = [text("instrument"), text("quantity"), text("reserved"), text("percent_reserved"), text("actual"), text("percent_actual")]
      @headers.insert(1, report_by_header) if @report_by != "instrument"
    end

    def init_report(&report_on)
      report = Reports::InstrumentUtilizationReport.new(report_data)
      report.build_report(&report_on)

      @totals = report.totals
      @label_columns = report.key_length

      rows = report.rows
      page_report(rows)
    end

    def init_report_data
      @totals = [0, 0]
      @report_data = report_data

      @report_data.each do |res|
        @totals[0] += to_hours(res.duration_mins)
        @totals[1] += to_hours(res.actual_duration_mins)
      end

      reservation = @report_data.first
      @headers += report_attributes(reservation, reservation.product)
    end

  end

end
