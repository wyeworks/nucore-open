# frozen_string_literal: true

class InstrumentStatusFetcher

  def initialize(facility)
    @facility = facility
  end

  def statuses
    @instrument_statuses = instruments.map do |instrument|
      instrument_status_for(instrument)
    end
  end

  private

  def instruments
    @facility.instruments.order(:id).includes(:relay).select { |instrument| instrument.relay&.networked_relay? }
  end

  def instrument_status_for(instrument)
    # Always return true/on if the relay feature is disabled
    return InstrumentStatus.new(on: true, instrument: instrument) unless SettingsHelper.relays_enabled_for_admin?

    key = instrument.relay.status_cache_key
    return status_cache[key] if status_cache.key?(key)

    begin
      status_cache[key] = InstrumentStatus.new(on: instrument.relay.get_status, instrument: instrument)
    rescue => e
      status_cache[key] = InstrumentStatus.new(error_message: e.message, instrument: instrument)
    end
  end

  def status_cache
    @status_cache ||= {}
  end

end
