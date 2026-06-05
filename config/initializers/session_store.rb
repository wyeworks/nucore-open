# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

ssl = Rails.application.config.force_ssl

Rails.application.config.session_store(
  :cookie_store,
  key: "_nucore_session",
  httponly: true,
  secure: ssl,
  same_site: (ssl ? :none : :lax)
)
