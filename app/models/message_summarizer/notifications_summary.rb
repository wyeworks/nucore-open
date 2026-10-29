# frozen_string_literal: true

class MessageSummarizer::NotificationsSummary < MessageSummarizer::MessageSummary
  def in_context?
    any?
  end

  private

  def allowed?
    ability.can?(:read, Notification)
  end

  def get_count
    user.notifications.active.count
  end

  def i18n_key
    "pages.notices"
  end

  def path
    controller.notifications_path
  end

  def user
    controller.current_user
  end
end
