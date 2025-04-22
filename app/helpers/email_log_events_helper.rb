# frozen_string_literal: true

module EmailLogEventsHelper
  def decorated_log_events(events)
    events.map { |event| EmailLogEventPresenter.new(event) }
  end
end
