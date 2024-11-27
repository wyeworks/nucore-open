# frozen_string_literal: true

# Support for finding the next available time and moving a reservation
# up to that next time slot
module Reservations::MovingUp

  #
  # Returns a new reservation with the reserve_*_at times updated
  # to the next accommodating time slot on the calendar from NOW. Returns nil
  # if there is no such time slot. For read-only purposes.
  def earliest_possible
    next_res = product.next_available_reservation(
      after: 1.minute.from_now,
      duration: duration_mins.minutes,
      options: {
        exclude: self, user:,
        until: reserve_start_at
      }
    )

    return nil if next_res.nil? || next_res.reserve_start_at >= reserve_start_at
    next_res
  end

  def move_to_earliest
    earliest_found = earliest_possible
    if earliest_found
      self.reserve_start_at = earliest_found.reserve_start_at.change(sec: 0)
      self.reserve_end_at = earliest_found.reserve_end_at.change(sec: 0)
      if save
        return true
      else
        errors.add(:base, :move_failed)
      end
    else
      errors.add(:base, :cannot_move)
    end
    false
  end

  # It is possible to move the reservation to the current time?
  def movable_to_now?
    product.online? &&
      !(canceled? || order_detail.complete? || in_grace_period? || earliest_possible.nil?) # TODO: refactor?
  end

end
