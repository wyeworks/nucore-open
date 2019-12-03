# frozen_string_literal: true

module ProblemOrderDetailsHelper

  def problem_order_date_header(show_reservation_start_at)
    if show_reservation_start_at
      t(".th.actual_start")
    else
      Order.human_attribute_name(:ordered_at)
    end
  end

  def problem_order_date(order_detail, show_reservation_start_at)
    date =
      if show_reservation_start_at
        order_detail.reservation.actual_start_at
      else
        order_detail.ordered_at
      end

    format_usa_datetime(date)
  end

end
