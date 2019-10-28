# frozen_string_literal: true

require_relative "production.rb"

Nucore::Application.configure do

  config.action_mailer.delivery_method = :sendmail # :smtp
  Rails.application.routes.default_url_options =
    config.action_mailer.default_url_options = { host: "corum-test.umass.edu", protocol: "http" }

end
