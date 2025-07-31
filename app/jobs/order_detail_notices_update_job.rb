# frozen_string_literal: true

class OrderDetailNoticesUpdateJob < ApplicationJob
  def perform(order_detail)
    order_detail.set_problem_and_notices

    order_detail.update_columns(
      notice_keys: order_detail.notices,
      problem_keys: order_detail.problems,
      problem: order_detail.problem,
    )
  end
end
