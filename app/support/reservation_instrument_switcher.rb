# frozen_string_literal: true

class ReservationInstrumentSwitcher

  attr_reader :reservation

  def initialize(reservation)
    @reservation = reservation
  end

  def switch_on!
    raise relay_error_msg("on", "can't switch") unless reservation.can_switch_instrument_on?

    if switch_relay_on
      @reservation.start_reservation!
    else
      raise relay_error_msg("on", "relay status")
    end
    instrument.instrument_statuses.create(is_on: true)
  end

  def switch_off!
    raise relay_error_msg("off", "can't switch") unless reservation.can_switch_instrument_off?

    if switch_relay_off == false
      @reservation.end_reservation!
    else
      raise relay_error_msg("off", "relay status")
    end
    instrument.instrument_statuses.create(is_on: false)
  end

  private

  def switch_relay_off
    if relays_enabled?
      relay.deactivate
      relay.get_status
    else
      false
    end
  end

  def switch_relay_on
    if relays_enabled?
      relay.activate
      relay.get_status
    else
      true
    end
  end

  def relays_enabled?
    SettingsHelper.relays_enabled_for_reservation?
  end

  def instrument
    reservation.product
  end

  def relay
    instrument.relay
  end

  def relay_error_msg(switch, reason)
    Rollbar.error("Failed to switch #{switch} reservation #{@reservation.id}, relay status: #{relay.get_status}, reason: #{reason}") if defined?(Rollbar)
    "An error was encountered while attempting to toggle the instrument. Please try again."
  end

end
