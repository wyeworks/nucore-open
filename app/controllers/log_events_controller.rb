# frozen_string_literal: true

class LogEventsController < GlobalSettingsController

  include CsvEmailAction

  def index
    report = Reports::LogEventsReport.new(
      start_date: parse_usa_date(params[:start_date]),
      end_date: parse_usa_date(params[:end_date]),
      events: params[:events],
      query: params[:query],
    )

    respond_to do |format|
      format.html do
        @log_events = report.log_events.paginate(per_page: 50, page: params[:page])
      end

      format.csv do
        queue_csv_report_email(report)
      end
    end
  end

end
