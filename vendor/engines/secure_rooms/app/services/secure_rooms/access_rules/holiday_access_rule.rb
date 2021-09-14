# frozen_string_literal: true

module SecureRooms

  module AccessRules

    class HolidayAccessRule < BaseRule
      def evaluate
        deny!(:holiday_access_restricted) if deny_holiday_access?
      end

      def deny_holiday_access?
        card_reader.ingress? && !Holiday.allow_access?(user, secure_room, Time.current)
      end

    end

  end

end
