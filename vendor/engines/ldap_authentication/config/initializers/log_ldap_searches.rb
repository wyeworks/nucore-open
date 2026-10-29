# frozen_string_literal: true

module LdapAuthentication
  class LogSubscriber < ActiveSupport::LogSubscriber
    def search(event)
      render(event, "Search #{event.payload[:uid]}: #{event.payload[:results].count} results")
    end

    private

    def render(event, string, display_color: GREEN)
      return unless logger.debug?

      prefix = color("[LdapAuthentication] (#{event.duration.round(1)}ms)", display_color, true)
      debug "#{prefix} #{string}"
    end
  end
end

LdapAuthentication::LogSubscriber.attach_to :ldap_authentication
