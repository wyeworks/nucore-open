# frozen_string_literal: true

class EmailLogEventsController < GlobalSettingsController

  def index
    @email_log_events = LogEvent.with_email_type.paginate(
      per_page: 50, page: params[:page]
    ).includes(:loggable).reverse_chronological
  end

end
