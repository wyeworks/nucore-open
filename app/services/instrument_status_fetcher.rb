# frozen_string_literal: true

class InstrumentStatusFetcher

  def initialize(facility, instrument_ids = nil)
    @facility = facility
    @instrument_ids = instrument_ids
  end

  # Returns statuses for instruments.
  # When refresh: true, polls relays and updates DB.
  # When refresh: false, returns last known statuses from the database.
  def statuses(refresh: false)
    if refresh
      instruments.filter_map { |instrument| refresh_status(instrument) }
    else
      instruments.map { |instrument| last_status_for(instrument) }
    end
  end

  private

  def refresh_status(instrument)
    return nil unless instrument.relay&.networked_relay?

    # When relays are disabled, save status as "on" without polling
    unless SettingsHelper.relays_enabled_for_admin?
      return InstrumentStatus.set_status_for(instrument, is_on: true)
    end

    begin
      is_on = instrument.relay.get_status
      InstrumentStatus.set_status_for(instrument, is_on:)
    rescue => e
      status = instrument.instrument_status || InstrumentStatus.new(instrument:)
      status.error_message = e.message
      status
    end
  end

  def instruments
    scope = @facility.instruments.order(:id).includes(:relay, :instrument_status)
    scope = scope.where(id: @instrument_ids) if @instrument_ids.present?
    scope.select { |instrument| instrument.relay&.networked_relay? }
  end

  # Returns the last known status from the database without polling the relay.
  def last_status_for(instrument)
    status = instrument.instrument_status

    # If relays are disabled, return last status or create a new "on" status
    unless SettingsHelper.relays_enabled_for_admin?
      return status || InstrumentStatus.new(on: true, instrument:)
    end

    # Return last status or unknown state if none exists
    status || InstrumentStatus.new(instrument:, is_on: nil)
  end

end
