# frozen_string_literal: true

module Devise

  module Models

    SamlAuthenticatableWithCustomError = SamlAuthenticatable

  end

  module Strategies

    class SamlAuthenticatableWithCustomError < SamlAuthenticatable

      private

      # In the original SamlAuthenticatable, this method calls fail!(:invalid), which
      # causes Devise to use the error message defined in devise.failure.invalid. That
      # error message is used by other strategies, including the email and password strategy
      # that we also use, so if we change the message we'll incorrectly affect the other
      # strategies as well. Therefore, we override the method responsible for failing
      # authentication to call fail!(:saml_invalid), which allows us to specify a separate
      # failure message for authentication via SAML.
      def failed_auth(msg)
        log_to_rollbar(msg) if defined?(Rollbar)
        DeviseSamlAuthenticatable::Logger.send(msg)
        fail!(error_message.html_safe)
        Devise.saml_failed_callback.new.handle(@response, self) if Devise.saml_failed_callback # rubocop:disable Style/SafeNavigation
      end

      def failed_auth_user_attributes
        attribute_map = Devise.saml_attribute_map_resolver.new("").attribute_map
        saml_response = ::SamlAuthenticatable::SamlResponse.new(@response.attributes, attribute_map)
        SamlAuthentication::SamlAttributes.new(saml_response).to_h
      end

      def error_message
        I18n.t(
          "devise.failure.saml_invalid",
          username: failed_auth_user_attributes[:username]&.first,
          email: failed_auth_user_attributes[:email]&.first
        )
      end

      def log_to_rollbar(msg)
        Rollbar.warn(msg, attributes: failed_auth_user_attributes) unless msg == "Resource could not be found"
      end

    end

  end

end

Warden::Strategies.add(:saml_authenticatable_with_custom_error, Devise::Strategies::SamlAuthenticatableWithCustomError)

Devise.add_module(:saml_authenticatable_with_custom_error,
                  route: :saml_authenticatable,
                  strategy: true,
                  controller: :saml_sessions,
                  model: "devise_saml_authenticatable/model")
