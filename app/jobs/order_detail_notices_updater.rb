# frozen_string_literal: true

class OrderDetailNoticesUpdater < ApplicationJob
  def perform(order_detail)
    notices_service = OrderDetails::NoticesService.new(order_detail)

    order_detail.update_columns(
      notices: notices_service.notices,
      problems: notices_service.problems,
    )
  end
end
