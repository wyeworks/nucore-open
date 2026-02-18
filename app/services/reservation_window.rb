# frozen_string_literal: true

##
# Computes reservation window for reservation
# create/edit form
class ReservationWindow
  def initialize(reservation, user)
    @reservation = reservation
    @user = user
  end

  def max_window
    return 365 if operator?

    @reservation.longest_reservation_window(price_groups)
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

  ##
  # Use all price groups product since conditions might
  # change depending on the selected account
  def price_groups
    @reservation.product.price_groups || []
  end
end
