# frozen_string_literal: true

module EmailLogEventsHelper
  EMAIL_OBJECT_THRESHOLD = 50

  def decorated_log_events(events)
    events.map { |event| EmailLogEventPresenter.new(event) }
  end

  def email_object_tag(email_object, **kwargs)
    if email_object.length > EMAIL_OBJECT_THRESHOLD
      content = truncate(email_object, length: EMAIL_OBJECT_THRESHOLD)
      kwargs[:data] = { toggle: "tooltip" }
      kwargs[:title] = email_object
    else
      content = email_object
    end

    content_tag("span", content, **kwargs)
  end
end
