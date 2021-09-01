# frozen_string_literal: true

module SecureRooms

  module AccessRules

    class ScheduleRule < BaseRule

      # TODO: Consider refactoring to make this logic more explicit.
      def evaluate
        deny!(:no_schedule) if secure_room.schedule_rules.none?
        deny!(:outside_schedule) unless secure_room.schedule_rules.cover?(Time.current)
        deny!(:not_in_group) unless secure_room.available_schedule_rules(user).cover?(Time.current)
      end

    end

  end

end
