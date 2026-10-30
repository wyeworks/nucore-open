# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class ArchivedProductRule < BaseRule
      def evaluate
        deny!(:archived) if secure_room.is_archived?
      end
    end
  end
end
