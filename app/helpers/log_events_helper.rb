# frozen_string_literal: true

module LogEventsHelper

  def log_events_options
    LogEventSearcher::ALLOWED_EVENTS.map { |event| [dropdown_title(event), event] }.sort
  end

  def dropdown_title(event)
    text("dropdown_titles.#{event}", default: event.to_sym)
  end

end
