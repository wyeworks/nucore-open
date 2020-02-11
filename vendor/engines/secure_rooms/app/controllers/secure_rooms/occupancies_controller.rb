# frozen_string_literal: true

module SecureRooms

  class OccupanciesController < ApplicationController

    layout "plain"

    before_action :load_secure_room

    def index
      @refresh_url = refresh_facility_secure_room_occupancies_url(current_facility, @secure_room.dashboard_token)
    end

    def refresh
      render partial: "secure_rooms/shared/secure_rooms_dashboard", locals: { room: @secure_room }
    end

    private

    def load_secure_room
      @secure_room = SecureRoom.find_by!(dashboard_token: params[:secure_room_id])
    end

  end

end
