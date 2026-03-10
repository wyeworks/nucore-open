# frozen_string_literal: true

class ReservationInstrumentSwitcher

  attr_reader :reservation

  def initialize(reservation)
    @reservation = reservation
  end

  def switch_on!
    cannot_switch_instrument! unless reservation.can_switch_instrument_on?

    switch_relay_on!
    auto_end_previous_reservations
    @reservation.start_reservation!
  end

  def switch_off!
    cannot_switch_instrument! unless reservation.can_switch_instrument_off?

    switch_relay_off!
    @reservation.end_reservation!
  end

  private

  def switch_relay_off!
    if relays_enabled?
      InstrumentStatus.with_lock_for(instrument) do
        relay.deactivate
      end
    end
  end

  def switch_relay_on!
    if relays_enabled?
      InstrumentStatus.with_lock_for(instrument) do
        relay.activate
      end
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

  def auto_end_previous_reservations
    return unless SettingsHelper.feature_on?(:auto_end_reservations_on_next_start)

    AutoEndPreviousReservation.new(instrument, reservation.user).end_previous_reservations!
  rescue => e
    Rails.logger.error "AutoEndPreviousReservation failed: #{e.message}"
  end

  def cannot_switch_instrument!
    raise NUCore::Error, I18n.t("reservations.instrument_switcher.cannot_switch_error")
  end

end
