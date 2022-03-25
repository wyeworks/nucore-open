# frozen_string_literal: true

require "devise/strategies/database_authenticatable"

# This is for use in the development environment where you may have
# users in the database that were created by other strategies (e.g. LDAP)
# but you don't want to always be connecting to the LDAP server.
# This will allow you to log in as any user.

module Devise

  module Models

    module UsernameOnlyAuthenticatable

      def valid_password?(_password)
        true
      end

    end

  end

  module Strategies

    class UsernameOnlyAuthenticatable < DatabaseAuthenticatable
    end

  end

end

Warden::Strategies.add(:username_only_authenticatable, Devise::Strategies::UsernameOnlyAuthenticatable)
