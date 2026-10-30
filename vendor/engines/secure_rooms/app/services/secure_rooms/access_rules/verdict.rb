# frozen_string_literal: true

module SecureRooms
  module AccessRules
    class Verdict
      include TextHelpers::Translation

      attr_reader(
        :reason,
        :user,
        :card_reader,
        :result_code,
        :selected_account,
        :accounts,
        :card_number,
      )

      def initialize(result_code, reason, user, card_reader, options = {})
        @result_code = result_code
        @user = user
        @card_reader = card_reader
        @reason = translate_reason(reason)
        @selected_account = options[:selected_account]
        @accounts = options[:accounts]
        @card_number = options[:card_number]
      end

      def pass?
        has_result_code?(:pass)
      end

      def denied?
        has_result_code?(:deny)
      end

      def granted?
        has_result_code?(:grant)
      end

      def pending?
        has_result_code?(:pending)
      end

      def has_result_code?(code)
        @result_code == code
      end

      def translation_scope
        "secure_rooms/access_rules.reasons"
      end

      private

      def translate_reason(key)
        text(key) if key.present?
      end
    end
  end
end
