class ReservationWindow
  def initialize(reservation, user)
    @reservation = reservation
    @user = user
  end

  def max_window
    return 365 if operator?
    @reservation.longest_reservation_window(@reservation.order_detail.price_groups)
  end

  def max_days_ago
    operator? ? -365 : 0
  end

  def min_date
    max_days_ago.days.from_now.strftime("%Y%m%d")
  end

  def max_date
    max_window.days.from_now.strftime("%Y%m%d")
  end

  private

  def operator?
    @user.operator_of?(@reservation.facility)
  end
end
