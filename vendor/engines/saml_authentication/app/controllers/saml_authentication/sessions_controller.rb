# frozen_string_literal: true

module SamlAuthentication

  class SessionsController < Devise::SamlSessionsController

    before_action :store_logging_out_username, only: :destroy
    after_action :store_winning_strategy, only: :create

    # See https://github.com/apokalipto/devise_saml_authenticatable/issues/181#issuecomment-696904192
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error

    def handle_validation_error(exception)
      ::Rails.logger.warn "There was an error trying to log in the SAML user '#{exception}'"

      flash[:alert] = I18n.t("devise.failure.saml_update_failed").html_safe
      redirect_to new_user_session_path, allow_other_host: true
    end

    # Overrides SamlSessionsController.
    #
    # The default behavior for IdP-initiated signout uses a database-backed
    # User#saml_session_index_key, which upon invalidation will invalidate _all_
    # NUcore sessions the user has open, even on other computers. With this override
    # you are only signed out the current browser's session.
    def idp_sign_out
      if params[:SAMLRequest] # IdP initiated logout
        idp_initiated_sign_out
      elsif params[:SAMLResponse]
        sp_initiated_sign_out
      else
        head :invalid_request
      end
    end

    protected

    # Remove recall, so failures redirect back to sign_in page
    def auth_options
      { scope: resource_name }
    end

    # Override SamlSessionsController
    #
    # Some IdP providers require the name_identifier_value of the LogoutRequest
    # to match the username of the current user.
    def after_sign_out_path_for(_resource_or_scope)
      idp_entity_id = get_idp_entity_id(params)
      request = OneLogin::RubySaml::Logoutrequest.new
      config = saml_config(idp_entity_id).dup
      config.name_identifier_value = @signed_out_username
      request.create(config)
    end

    # Override Devise::SessionsController to add allow_other_host for SAML redirects
    # Rails 7.2 requires explicit allow_other_host for external redirects
    def respond_to_on_destroy
      respond_to do |format|
        format.all { head :no_content }
        format.any(*navigational_formats) do
          redirect_to after_sign_out_path_for(resource_name),
                      status: Devise.responder.redirect_status,
                      allow_other_host: true
        end
      end
    end

    private

    # SP is NUcore. User is already logged out by the sessions#delete call
    def sp_initiated_sign_out
      if Devise.saml_sign_out_success_url
        redirect_to Devise.saml_sign_out_success_url, allow_other_host: true
      else
        redirect_to action: :new
      end
    end

    def idp_initiated_sign_out
      sign_out(resource_name)

      saml_config = saml_config(get_idp_entity_id(params))
      logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], settings: saml_config)

      redirect_to generate_idp_logout_response(saml_config, logout_request.id), allow_other_host: true
    end

    # Store the username for use in `after_sign_out_path_for`
    def store_logging_out_username
      @signed_out_username = current_user.public_send(Devise.saml_default_user_key)
    end

    # This will be used to choose which Logout link is shown to the user.
    # https://github.com/apokalipto/devise_saml_authenticatable/wiki/Supporting-multiple-authentication-strategies
    def store_winning_strategy
      warden.session(resource_name)[:strategy] = :saml_authenticatable
    end

  end

end
