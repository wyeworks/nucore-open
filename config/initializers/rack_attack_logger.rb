# frozen_string_literal: true

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _instrumenter_id, payload|
  request = payload[:request]

  request_id = request.try(:request_id)

  prefix = request_id ? "[#{request_id}]" : ""

  Rails.logger.info do
    [
      prefix,
      "Request throttled for",
      request.try(:remote_ip) || request.ip,
      request.request_method,
      request.fullpath,
      "(#{request.user_agent})",
    ].join(" ")
  end
end
