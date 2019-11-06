# frozen_string_literal: true

require "saml_authentication/saml_attributes"

module SamlAuthentication

  class UserUpdater

    def initialize(skip_attributes: [], **_args)
      @skip_attributes = Array(skip_attributes)
    end

    def call(user, saml_response, _auth_value)
      attributes = SamlAttributes.new(saml_response).except(*@skip_attributes).merge(
        encrypted_password: nil,
        password_salt: nil,
      )
      user.update!(attributes)
    end

  end

end
