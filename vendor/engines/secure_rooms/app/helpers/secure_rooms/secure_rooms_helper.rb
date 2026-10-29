# frozen_string_literal: true

module SecureRooms
  module SecureRoomsHelper
    def secure_room_ability
      SecureRooms::CardNumberAbility.new(current_user, current_facility)
    end
  end
end
