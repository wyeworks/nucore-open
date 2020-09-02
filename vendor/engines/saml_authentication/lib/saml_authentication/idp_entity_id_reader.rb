# frozen_string_literal: true

module SamlAuthentication

  # Overrides DeviseSamlAuthenticatable::DefaultIdpEntityIdReader.
  #
  # The default IdpEntityIdReader triggers an error on SLO because that request to
  # us has a SAMLResponse parameter, which does not get parsed by OneLogin::RubySaml::Response
  # correctly: "Issuer of the Response not found or multiple."
  #
  # Ideally, we will issue a PR to the devise_saml_authenticatable gem with these
  # changes so it is corrected upstream.
  class IdpEntityIdReader

    def self.entity_id(params)
      if params[:action] == "idp_sign_out" && params[:SAMLResponse]
        OneLogin::RubySaml::Logoutresponse.new(
          params[:SAMLResponse],
          Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuer
      else
        original_implementation(params)
      end
    end

    # Copied rather than inherited from default class for clarity.
    def self.original_implementation(params)
      if params[:SAMLRequest]
        OneLogin::RubySaml::SloLogoutrequest.new(
          params[:SAMLRequest],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuer
      elsif params[:SAMLResponse]
        OneLogin::RubySaml::Response.new(
          params[:SAMLResponse],
          settings: Devise.saml_config,
          allowed_clock_drift: Devise.allowed_clock_drift_in_seconds,
        ).issuers.first
      end
    end

  end

end
