# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_authorization_check

  def not_found
    render_error("not_found", :not_found)
  end

  def internal_server_error
    render_error("internal_server_error", :internal_server_error)
  end

  def forbidden
    if request.env["action_dispatch.exception"].instance_of? NUCore::NotPermittedWhileActingAs
      render_error("acting_error", :forbidden)
    elsif current_user
      render_error("forbidden", :forbidden)
    else
      # if current_user is nil, the user should be redirected to login
      store_location_for(:user, request.fullpath)
      redirect_to new_user_session_path
    end
  end

  private

  def render_error(template, status)
    render template, status: status.to_sym, formats: formats_with_html_fallback
  rescue ActionController::UnknownFormat
    head status
  end

end
