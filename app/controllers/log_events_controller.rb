# frozen_string_literal: true

class LogEventsController < GlobalSettingsController

  include CsvEmailAction

  def index
    respond_to do |format|
      format.html do
        @log_events = report.log_events.paginate(per_page: 50, page: params[:page])
      end

      format.csv do
        queue_csv_report_email(
          report_class,
          **report_args
        )
      end
    end
  end

  private

  def report_class
    Reports::LogEventsReport
  end

  def report_args
    {
      start_date: parse_usa_date(params[:start_date]),
      end_date: parse_usa_date(params[:end_date]),
      events: params[:events],
      query: params[:query],
    }
  end

  def report
    @report ||= report_class.new(**report_args)
  end

end
