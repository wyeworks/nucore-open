# frozen_string_literal: true

# Used by the reservations controllers to find the default
# reservation times to display
class NextAvailableReservationFinder
  attr_reader :product, :start_at

  def initialize(product, start_at: nil)
    @product = product
    @start_at = start_at || 1.minute.from_now
  end

  def next_available_for(current_user, acting_user)
    options = current_user.can_override_restrictions?(product) ? {} : { user: acting_user }
    next_available = product.next_available_reservation(
      after: start_at,
      duration: default_duration,
      options:
    )
    next_available ||= default_reservation
    next_available.round_reservation_times
  end

  private

  def default_reservation
    Reservation.new(product:,
                    reserve_start_at: start_at,
                    reserve_end_at: start_at + default_duration)
  end

  def default_duration
    if product.daily_booking?
      (product.min_reserve_days || 1).days
    else
      (product.min_reserve_mins.to_i > 0 ? product.min_reserve_mins : 30).minutes
    end
  end
end
