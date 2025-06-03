# frozen_string_literal: true

class ErrorsController < ApplicationController
  skip_authorization_check

  def not_found
    render_error("not_found", :not_found)
  end

  def internal_server_error
    render_error(nil, :internal_server_error)
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
    if status == :internal_server_error
      send_static_error_page
    else
      render template, status:, formats: formats_with_html_fallback
    end
  rescue ActionController::UnknownFormat
    head status
  end

  def send_static_error_page
    static_file_path = Rails.public_path.join("500.html")
    if File.exist?(static_file_path)
      send_file static_file_path, status: :internal_server_error, type: "text/html"
    else
      head :internal_server_error
    end
  end

end
