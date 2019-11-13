# frozen_string_literal: true

require "ldap_authentication/user_lookup"

module LdapAuthentication

  module UsersControllerExtension

    def service_username_lookup(username)
      LdapAuthentication::UserLookup.new.call(username)
    end

  end

end
