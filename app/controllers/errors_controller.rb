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
    if request.env["action_dispatch.exception"].instance_of? NUCore::NotPermittedWhileActingAs
      render "acting_error", status: 403, formats: formats_with_html_fallback
    elsif current_user
      render "403", status: 403, formats: formats_with_html_fallback
    else
      # if current_user is nil, the user should be redirected to login
      store_location_for(:user, request.fullpath)
      redirect_to new_user_session_path
    end
  end

end
