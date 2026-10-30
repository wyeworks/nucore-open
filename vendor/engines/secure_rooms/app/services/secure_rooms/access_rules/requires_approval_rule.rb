# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class RequiresApprovalRule < BaseRule
      def evaluate
        deny!(:not_on_access_list) unless secure_room.can_be_used_by?(user)
      end
    end
  end
end
