# frozen_string_literal: true

module SamlAuthentication

  class LogSubscriber < ActiveSupport::LogSubscriber

    def find_user(event)
      render(event, "Locating user from attributes: #{event.payload[:attributes]}")
      render(event, "Raw attributes: #{event.payload[:raw_attributes]}")
    end

    def fetching_metadata(event)
      render(event, "Fetching metadata from #{event.payload[:location]}")
    end
    private

    def render(event, string, display_color: GREEN)
      return unless logger.debug?

      prefix = color("[SamlAuthentication] (#{event.duration.round(1)}ms)", display_color, true)
      debug "#{prefix} #{string}"
    end

  end

end

SamlAuthentication::LogSubscriber.attach_to :saml_authentication
