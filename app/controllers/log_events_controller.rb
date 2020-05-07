# frozen_string_literal: true

class LogEventsController < GlobalSettingsController

  def index
    @log_events = LogEvent.search(
      start_date: parse_usa_date(params[:start_date]),
      end_date: parse_usa_date(params[:end_date]),
      events: params[:events],
      query: params[:query],
    ).includes(:user, :loggable).reverse_chronological.paginate(per_page: 50, page: params[:page])
  end

end
