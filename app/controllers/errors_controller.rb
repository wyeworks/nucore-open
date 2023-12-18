# frozen_string_literal: true

class ErrorsController < ApplicationController

  def not_found
    respond_to do |format|
      format.html { render status: :not_found }
    end
  rescue ActionController::UnknownFormat
    head :not_found
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: :internal_server_error }
    end
  rescue ActionController::UnknownFormat
    head :internal_server_error
  end

  def forbidden
    @error_message = if acting_error?
      "This function is unavailable while you are acting as another user."
    else
      "Sorry, you don't have permission to access this page."
    end

    if current_user || acting_error?
      respond_to do |format|
        format.html { render status: :forbidden }
      end
    else
      # if current_user is nil, the user should be redirected to login
      store_location_for(:user, request.fullpath)
      redirect_to new_user_session_path
    end
  rescue ActionController::UnknownFormat
    head :forbidden
  end

  def acting_error?
    request.env["action_dispatch.exception"].instance_of?(NUCore::NotPermittedWhileActingAs)
  end
  
end
