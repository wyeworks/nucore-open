# frozen_string_literal: true

module Reservations::RelaySupport
  def can_switch_instrument_on?(check_off = true)
    return false if canceled?
    return false unless product.relay # is relay controlled
    return false if product.offline?
    return false if check_off && can_switch_instrument_off?(false) # mutually exclusive
    return false unless actual_start_at.nil?   # already turned on
    return false unless actual_end_at.nil?     # already turned off
    return false if reserve_end_at < Time.zone.now # reservation is already over (missed reservation)
    return can_start_early? if reserve_start_at > Time.zone.now

    true
  end

  def can_switch_instrument_off?(check_on = true)
    return false if canceled?
    return false unless product.relay # is relay controlled
    return false if check_on && can_switch_instrument_on?(false) # mutually exclusive
    return false unless actual_end_at.nil?    # already ended
    return false if actual_start_at.nil?      # hasn't been started yet
    return false if order_detail.complete?

    true
  end

  def can_switch_instrument?
    can_switch_instrument_off? || can_switch_instrument_on?
  end

  def other_reservations_using_relay
    order_detail.reservation.product.schedule.reservations
                .active
                .relay_in_progress
                .where(order_details: { state: ["new", "inprocess", nil] })
                .not_this_reservation(self)
  end

  def other_reservation_using_relay?
    !order_detail.reservation.can_switch_instrument_off? || order_detail.reservation.other_reservations_using_relay.count > 0
  end
end
