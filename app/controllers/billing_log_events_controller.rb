# frozen_string_literal: true

class BillingLogEventsController < GlobalSettingsController

  def index
    @billing_log_events = LogEventSearcher.new(
      relation: LogEvent.with_billing_type,
      start_date: parse_usa_date(index_params[:start_date]),
      end_date: parse_usa_date(index_params[:end_date]),
      events: index_params[:events],
    ).search.includes(:loggable).reverse_chronological.paginate(
      per_page: 50, page: index_params[:page]
    )
  end

  def index_params
    params.permit(
      :start_date,
      :end_date,
      :page,
      events: []
    )
  end

end
