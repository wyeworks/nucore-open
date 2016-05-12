module Reports

  class InstrumentReportsController < ReportsController

    include InstrumentReporter

    delegate :reports, to: "self.class"

    def index
      @report_by = (params[:report_by].presence || "instrument")
      index = reports.keys.find_index(@report_by)
      render_report(index, &reports[@report_by])
    end

    def self.reports
      @reports ||= HashWithIndifferentAccess.new(
        instrument: -> (r) { [r.product.name] },
        account: -> (r) { [r.product.name, r.order_detail.account.to_s] },
        account_owner: -> (r) { [r.product.name, format_username(r.order_detail.account.owner.user)] },
        purchaser: -> (r) { [r.product.name, format_username(r.order_detail.order.user)] },
      )
    end

    private

    def init_report_headers
      @headers = [text("instrument"), text("quantity"), text("reserved"), text("percent_reserved"), text("actual"), text("percent_actual")]
      @headers.insert(1, report_by_header) if @report_by != "instrument"
    end

    def init_report(&report_on)
      report = Reports::InstrumentUtilizationReport.new(report_data)
      report.build_report &report_on

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
