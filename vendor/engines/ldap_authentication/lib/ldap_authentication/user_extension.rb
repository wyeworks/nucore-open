# frozen_string_literal: true

require "ldap_authentication/user_updater"

module LdapAuthentication
  module UserExtension
    extend ActiveSupport::Concern

    class_methods do
      # Overrides default from devise_ldap_authenticatable
      def find_for_ldap_authentication(attributes = {})
        resource = super
        resource unless resource.authenticated_locally?
      end
    end

    # Overrides the default no-op from devise_ldap_authenticatable
    def after_ldap_authentication
      UserUpdater.new(self).update_from_ldap
    end
  end
end
