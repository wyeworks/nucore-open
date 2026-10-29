# frozen_string_literal: true

module SecureRooms
  class CardNumberAbility
    include CanCan::Ability

    def initialize(user, facility)
      return unless user && facility

      if user.administrator? || user.facility_director_of?(facility) || user.facility_administrator_of?(facility) ||
      	 user.facility_senior_staff_of?(facility) || user.facility_staff_of?(facility)
      	can :edit, User
      end
    end
  end
end
