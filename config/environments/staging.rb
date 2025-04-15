# frozen_string_literal: true

require_relative "production"

Nucore::Application.configure do
  config.action_mailer.raise_delivery_errors = true
end
