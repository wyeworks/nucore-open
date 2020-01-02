# frozen_string_literal: true

class ProblemOrderMailerPreview < ActionMailer::Preview

  def notify_user
    order_detail = NUCore::Database.random(Reservation.user.joins(:order_detail).merge(OrderDetail.complete)).order_detail
    ProblemOrderMailer.notify_user(order_detail)
  end

  def notify_user_with_resolution_option
    order_detail = NUCore::Database.random(Reservation.user.joins(:order_detail).merge(OrderDetail.complete)).order_detail
    ProblemOrderMailer.notify_user_with_resolution_option(order_detail)
  end

end
