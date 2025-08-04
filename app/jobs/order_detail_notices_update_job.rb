# frozen_string_literal: true

class OrderDetailNoticesUpdateJob < ApplicationJob
  def perform(order_detail)
    order_detail.set_problem_and_notices

    order_detail.update_columns(
      notice_keys: order_detail.notice_keys,
      problem_keys: order_detail.problem_keys,
      problem: order_detail.problem,
    )
  end
end
