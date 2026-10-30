# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class RequiresUserRule < BaseRule
      def evaluate
        deny!(:user_not_found, card_number: params[:card_number]) if user.nil?
      end
    end
  end
end
