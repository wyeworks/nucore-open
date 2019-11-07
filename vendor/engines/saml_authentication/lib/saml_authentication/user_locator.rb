# frozen_string_literal: true

require "saml_authentication/saml_attributes"

module SamlAuthentication

  class UserLocator

    def call(model, saml_response, _auth_value)
      ActiveSupport::Notifications.instrument "find_user.saml_authentication" do |payload|
        attributes = SamlAttributes.new(saml_response)
        payload[:attributes] = attributes.to_h
        payload[:raw_attributes] = attributes.to_raw_h

        username = attributes[:username]
        email = attributes[:email]

        model.find_by(username: username) || model.find_by(email: email)
      end

    end

  end

end
