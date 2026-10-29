# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class OperatorRule < BaseRule
      def evaluate
        grant!(:operator) if user.user_roles.operator?(card_reader.facility)
      end
    end
  end
end
