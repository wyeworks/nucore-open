require "username_only_authenticatable"

Rails.application.config.to_prepare do
  if File.exist?("#{Rails.root}/config/ldap.yml")
    User.send(:devise, :ldap_authenticatable)

    class User

      # If a Devise Strategy calls `validate` with a resource and it returns false,
      # then the strategy chain is halted. Previous versions of the LDAP strategy
      # would only call `validate` with a fully authenticated resource, but 0.8+
      # will find the resource in the database first and then call against the LDAP
      # server. This prevents the LDAP authentication for external users.
      def self.find_for_ldap_authentication(attributes = {})
        resource = super
        resource unless resource.authenticated_locally?
      end

    end

    UsersController.send(:include, Ldap::UsersControllerExtension)
  end
end

#
# We don't set passwords via LDAP. If setting a password
# defer to the next strategy (encryptable or database_authenticatable)
Devise::Models::LdapAuthenticatable.module_eval do
  def password=(new_password)
    super
  end
end
