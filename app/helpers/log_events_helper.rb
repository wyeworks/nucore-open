# frozen_string_literal: true

module LogEventsHelper

  def log_events_options
    Reports::LogEventsReport::ALLOWED_EVENTS.map { |event| [dropdown_title(event), event] }.sort
  end

  def dropdown_title(event)
    text("dropdown_titles.#{event}", default: text("log_event/event_type.#{event}"))
  end

end
