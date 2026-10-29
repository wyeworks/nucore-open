# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class BaseRule
      attr_reader :user, :card_reader, :params

      delegate :secure_room, to: :card_reader

      def initialize(user, card_reader, params = {})
        @user = user
        @card_reader = card_reader
        @params = params
      end

      def call
        evaluate || pass
      end

      def evaluate
        raise NotImplementedError
      end

      def pass
        Verdict.new(:pass, :passed, @user, @card_reader)
      end

      def grant!(reason, options = {})
        Verdict.new(:grant, reason, @user, @card_reader, options)
      end

      def pending!(reason, options = {})
        Verdict.new(:pending, reason, @user, @card_reader, options)
      end

      def deny!(reason, options = {})
        Verdict.new(:deny, reason, @user, @card_reader, options)
      end
    end
  end
end
