# frozen_string_literal: true

module Nucore

  class ExceptionsApp
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)

      fallback_to_html_format_if_invalid_mime_type(request)

      @app.call(env)
    end

    private

    def fallback_to_html_format_if_invalid_mime_type(request)
      request.formats
    rescue ActionDispatch::Http::MimeNegotiation::InvalidType
      request.set_header "CONTENT_TYPE", "text/html"
    end
  end

end
