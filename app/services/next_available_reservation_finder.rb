# Used by the reservations controllers to find the default reservation times to display

class NextAvailableReservationFinder
  def initialize(product)
    @product = product
  end

  def next_available_for(current_user, acting_user)
    options = current_user.can_override_restrictions?(@product) ? {} : { user: acting_user }
    next_available = @product.next_available_reservation(
      after: 1.minute.from_now,
      duration: default_reservation_mins.minutes,
      options: options
    )
    next_available ||= default_reservation
    next_available.round_reservation_times
  end

  private

  def default_reservation
    Reservation.new(product: @product,
                    reserve_start_at: Time.current,
                    reserve_end_at: default_reservation_mins.minutes.from_now)
  end

  def default_reservation_mins
    @product.min_reserve_mins.to_i > 0 ? @product.min_reserve_mins : 30
  end
end
