# frozen_string_literal: true

ActiveSupport::Notifications.subscribe("background_error") do |_name, _start, _finish, _id, payload|
  exception = payload[:exception]
  options = payload[:information] ? { data: { message: payload[:information] } } : {}
  if defined?(ExceptionNotifier)
    ExceptionNotifier.notify_exception(exception, options)
  end
  Rails.logger.error exception
  Rails.logger.error exception.backtrace.try(:join, "\n")
  if defined?(Rollbar)
    Rollbar.error(exception)
  end
end
