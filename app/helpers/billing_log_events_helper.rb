# frozen_string_literal: true

module BillingLogEventsHelper
  OBJECT_LENGTH_THRESHOLD = 50

  def billing_log_events_options
    LogEvent::BILLING_EVENT_TYPES.map do |event_type|
      [event_type_label(event_type), event_type]
    end
  end

  def event_type_label(event_type)
    text("log_event/event_type.#{event_type}")
  end

  def decorated_log_events(events)
    events.map { |event| BillingLogEventPresenter.new(event) }
  end

  def object_tag(log_event_object, **kwargs)
    if log_event_object.length > OBJECT_LENGTH_THRESHOLD
      content = truncate(log_event_object, length: OBJECT_LENGTH_THRESHOLD)
      kwargs[:data] = { toggle: "tooltip" }
      kwargs[:title] = log_event_object
    else
      content = log_event_object
    end

    content_tag("span", content, **kwargs)
  end
end
