# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class EgressRule < BaseRule
      def evaluate
        grant!(:egress) if card_reader.egress?
      end
    end
  end
end
