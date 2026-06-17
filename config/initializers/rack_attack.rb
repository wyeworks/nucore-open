# frozen_string_literal: true

class Rack::Attack

  throttle("req/ip", limit: Settings.rack_attack.req_limit, period: Settings.rack_attack.req_period) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  throttle("logins/ip", limit: Settings.rack_attack.login_limit, period: Settings.rack_attack.login_period) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"] || {}
    retry_after = match_data[:period] || Settings.rack_attack.req_period

    [
      429,
      { "Content-Type" => "text/html", "Retry-After" => retry_after.to_s },
      [Rails.public_path.join("429.html").read],
    ]
  end

end

Rack::Attack.enabled = Settings.rack_attack&.enabled || false

Rails.application.config.middleware.use Rack::Attack
