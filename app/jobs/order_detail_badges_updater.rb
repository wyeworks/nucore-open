# frozen_string_literal: true

class OrderDetailBadgesUpdater < ApplicationJob
  def perform(order_detail)
    od_badges = OrderDetails::BadgesService.new(order_detail)

    order_detail.update_columns(
      status_badges: od_badges.statuses,
    )
  end
end
