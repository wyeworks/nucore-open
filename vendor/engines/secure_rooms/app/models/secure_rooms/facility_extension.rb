# frozen_string_literal: true

module SecureRooms
  module FacilityExtension
    extend ActiveSupport::Concern

    included do
      has_many :secure_rooms, inverse_of: :facility
    end
  end
end
