# frozen_string_literal: true

require "ldap_authentication/user_extension"
require "ldap_authentication/users_controller_extension"

module LdapAuthentication
  class Engine < Rails::Engine
    config.to_prepare do
      if LdapAuthentication.configured?
        User.send(:devise, :ldap_authenticatable)
        User.include LdapAuthentication::UserExtension
        UsersController.include LdapAuthentication::UsersControllerExtension
      end
    end
  end
end

Devise::Models::LdapAuthenticatable.module_eval do
  def password=(new_password)
    super
  end
end
