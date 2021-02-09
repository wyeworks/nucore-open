# frozen_string_literal: true

module Users

  class AuthChecker

    def initialize(user, password)
      @user = user
      @password = password
    end

    def authorized?(action, object)
      return false if @user.nil?

      kiosk_user_ability = Ability.new(@user, object)
      kiosk_user_ability.can?(action, object)
    end

    def authenticated?
      return false if @user.nil?
      return true if bypass_kiosk_auth?

      if @user.authenticated_locally?
        @user.valid_password?(@password)
      elsif ldap_enabled?
        @user.valid_ldap_authentication?(@password)
      end
    end

    def ldap_enabled?
      SettingsHelper.feature_on?(:uses_ldap_authentication) && LdapAuthentication.configured?
    end

    # TODO - Decide if we need to authenticate against employee ID, a reservation passcode, or IdP/LDAP API.
    # Starting with the easiest implementation while gathering feedback from potential users.
    def bypass_kiosk_auth?
      SettingsHelper.feature_on?(:bypass_kiosk_auth)
    end

  end

end
