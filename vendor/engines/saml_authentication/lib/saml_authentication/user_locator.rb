# frozen_string_literal: true

require "saml_authentication/saml_attributes"

module SamlAuthentication

  class UserLocator

    def call(model, saml_response, _auth_value)
      attributes = SamlAttributes.new(saml_response)
      username = attributes[:username]
      email = attributes[:email]

      model.find_by(username: username) || model.find_by(email: email)
    end

  end

end
