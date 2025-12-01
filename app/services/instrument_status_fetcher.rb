# frozen_string_literal: true

class InstrumentStatusFetcher

  def initialize(facility)
    @facility = facility
  end

  # Returns last known statuses from the database without polling relays.
  def statuses
    instruments.map do |instrument|
      last_status_for(instrument)
    end
  end

  # Refreshes status for a single instrument by polling its relay.
  # Returns the updated InstrumentStatus.
  def self.refresh_status(instrument)
    return nil unless instrument.relay&.networked_relay?

    # When relays are disabled, save status as "on" without polling
    unless SettingsHelper.relays_enabled_for_admin?
      return InstrumentStatus.set_status_for(instrument, is_on: true)
    end

    begin
      is_on = instrument.relay.get_status
      InstrumentStatus.set_status_for(instrument, is_on: is_on)
    rescue => e
      status = instrument.instrument_status || InstrumentStatus.new(instrument: instrument)
      status.error_message = e.message
      status
    end
  end

  private

  def instruments
    @facility.instruments.order(:id).includes(:relay, :instrument_status).select { |instrument| instrument.relay&.networked_relay? }
  end

  # Returns the last known status from the database without polling the relay.
  def last_status_for(instrument)
    status = instrument.instrument_status

    # If relays are disabled, return last status or create a new "on" status
    unless SettingsHelper.relays_enabled_for_admin?
      return status || InstrumentStatus.new(on: true, instrument: instrument)
    end

    # Return last status or unknown state if none exists
    status || InstrumentStatus.new(instrument: instrument, is_on: nil)
  end

end
