# frozen_string_literal: true

module OrderDetails

  class AssignmentNotifier < SimpleDelegator

    def notify
      if SettingsHelper.feature_on?("notifications.order_assignment_notifications") && assigned_user_changed?
        OrderAssignmentMailer.notify_assigned_user(__getobj__).deliver_later
      end
    end

    private

    def assigned_user_changed?
      assigned_user_id_previously_changed? && assigned_user.present?
    end

  end

end
