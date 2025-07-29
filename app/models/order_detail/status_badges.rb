# frozen_string_literal: true

module OrderDetail::StatusBadges
  extend ActiveSupport::Concern

  included do
    serialize :status_badges, Array

    after_commit :schedule_status_badge_update
  end

  def update_status_badges
    OrderDetailBadgesUpdater.perform_now(self)
  end

  def update_status_badges_later
    OrderDetailBadgesUpdater.perform_later(self)
  end

  def schedule_status_badge_update
    # TODO: maybe we shouldn't trigger this every time
    update_status_badges_later
  end
end
