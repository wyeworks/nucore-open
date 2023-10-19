# frozen_string_literal: true

require_relative "production.rb"

Nucore::Application.configure do

  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    api_key: ENV.fetch("MAILGUN_API_KEY", "123"),
    domain: ENV.fetch("MAILGUN_DOMAIN", "123"),
  }

  Rails.application.routes.default_url_options =
    config.action_mailer.default_url_options = { host: "nucore-open.herokuapp.com", protocol: "https" }

end
