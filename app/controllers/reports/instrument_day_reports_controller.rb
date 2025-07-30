# frozen_string_literal: true

module Reports

  class InstrumentDayReportsController < ReportsController

    include InstrumentReporter

    helper_method :export_csv_report_path
    helper_method :report_data_row

    def self.reports
      @reports ||= ActiveSupport::HashWithIndifferentAccess.new(
        reserved_quantity: ->(res) { Reports::InstrumentDayReport::ReservedQuantity.new(res) },
        reserved_hours: ->(res) { Reports::InstrumentDayReport::ReservedHours.new(res) },
        actual_quantity: ->(res) { Reports::InstrumentDayReport::ActualQuantity.new(res) },
        actual_hours: ->(res) { Reports::InstrumentDayReport::ActualHours.new(res) },
      )
    end

    # TODO: Currently the only "raw" instrument report type is the unavailable
    # report which covers admin and offline reservations. If there is a need
    # for other instrument-based raw reports, this method, along with the
    # javascript that manages the "Export Raw" link will need to change.
    def export_csv_report_path
      facility_instrument_unavailable_export_raw_reports_path(format: :csv)
    end

    def export_raw_visible?
      false
    end

    protected

    def tab_offset
      InstrumentReportsController.reports.size
    end

    private

    def init_report_headers
      @headers ||= [text("instrument")] + I18n.t("date.day_names")
    end

    def init_report(&report_on)
      report = Reports::InstrumentDayReport.new(report_data)
      report.build_report(&report_on)
      @totals = report.totals
      rows = report.rows

      page_report rows
    end

    def init_report_data
      @report_data = report_data
      reservation = @report_data.first
      @headers += report_attributes(reservation, reservation.product)
    end

    def report_data_row(reservation)
      row = Array.new(7)
      stat = @report_on.call(reservation)
      row[stat.day] = stat.value
      row.unshift(reservation.product.name) + report_attribute_values(reservation, reservation.product)
    end

  end

end
