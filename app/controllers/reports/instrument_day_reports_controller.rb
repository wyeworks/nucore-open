module Reports

  class InstrumentDayReportsController < ReportsController

    include InstrumentReporter
    helper_method :report_data_row

    def index
      @report_by = (params[:report_by].presence || "instrument")
      index = reports.keys.find_index(@report_by) + 4
      render_report(index, nil, &reports[@report_by])
    end

    def reports
      HashWithIndifferentAccess.new(
        reserved_quantity: -> (res) { Reports::InstrumentDayReport::ReservedQuantity.new(res) },
        reserved_hours: -> (res) { Reports::InstrumentDayReport::ReservedHours.new(res) },
        actual_quantity: -> (res) { Reports::InstrumentDayReport::ActualQuantity.new(res) },
        actual_hours: -> (res) { Reports::InstrumentDayReport::ActualHours.new(res) }
      )
    end

    private

    def init_report_headers(_report_on_label)
      @headers ||= %w(Instrument Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
    end

    def init_report(_report_on_label, &report_on)
      report = Reports::InstrumentDayReport.new(report_data)
      report.build_report &report_on
      @totals = report.totals
      rows = report.rows

      page_report rows
    end

    def init_report_data(_report_on_label)
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
