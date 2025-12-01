# frozen_string_literal: true

class InstrumentStatusFetcher

  def initialize(facility)
    @facility = facility
  end

  # Returns stored statuses from the database without polling relays.
  # This provides fast loading at the expense of potentially outdated information.
  def statuses
    instruments.map do |instrument|
      cached_status_for(instrument)
    end
  end

  # Refreshes status for a single instrument by polling its relay.
  # Returns the updated InstrumentStatus.
  def self.refresh_status(instrument)
    return nil unless instrument.relay&.networked_relay?
    return InstrumentStatus.new(on: true, instrument: instrument) unless SettingsHelper.relays_enabled_for_admin?

    begin
      is_on = instrument.relay.get_status
      InstrumentStatus.set_status_for(instrument, is_on: is_on)
    rescue => e
      status = instrument.current_instrument_status || InstrumentStatus.new(instrument: instrument)
      status.error_message = e.message
      status
    end
  end

  private

  def instruments
    @facility.instruments.order(:id).includes(:relay, :instrument_statuses).select { |instrument| instrument.relay&.networked_relay? }
  end

  # Returns the cached status from the database without polling the relay.
  def cached_status_for(instrument)
    # Always return true/on if the relay feature is disabled
    return InstrumentStatus.new(on: true, instrument: instrument) unless SettingsHelper.relays_enabled_for_admin?

    status = instrument.current_instrument_status
    if status
      status
    else
      # No cached status exists - return unknown state
      InstrumentStatus.new(instrument: instrument, is_on: nil)
    end
  end

end
