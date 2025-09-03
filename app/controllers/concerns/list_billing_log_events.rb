# frozen_string_literal: true

module ListBillingLogEvents
  def index
    @billing_log_events = LogEventSearcher.new(
      relation: LogEvent.with_billing_type,
      start_date: parse_usa_date(index_params[:start_date]),
      end_date: parse_usa_date(index_params[:end_date]),
      events: index_params[:events],
      invoice_number: index_params[:invoice_number],
      payment_source: index_params[:payment_source],
      ).search.includes(:loggable, :email_file_attachment).reverse_chronological.paginate(
      per_page: 50, page: index_params[:page]
    )
  end

  def index_params
    params.permit(
      :start_date,
      :end_date,
      :page,
      :invoice_number,
      :payment_source,
      events: []
    )
  end
end
