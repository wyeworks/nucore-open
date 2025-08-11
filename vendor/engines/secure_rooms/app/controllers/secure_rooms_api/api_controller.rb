# frozen_string_literal: true

module SecureRoomsApi

  class ApiController < ApplicationController

    skip_before_action :authenticate_user!

    http_basic_authenticate_with(
      name: Rails.application.secrets.secure_rooms_api[:basic_auth_name],
      password: Rails.application.secrets.secure_rooms_api[:basic_auth_password],
    )

    skip_before_action :verify_authenticity_token

  end

end
