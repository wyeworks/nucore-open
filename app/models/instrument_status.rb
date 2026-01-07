# frozen_string_literal: true

class InstrumentStatus < ApplicationRecord

  belongs_to :instrument, inverse_of: :instrument_status

  validates_numericality_of :instrument_id

  alias_attribute :on, :is_on

  attr_accessor :error_message

  def self.set_status_for(instrument, is_on:)
    transaction do
      update_all_shared_instruments(instrument, is_on: is_on)
      find_by(instrument: instrument)
    end
  end

  def self.with_lock_for(instrument)
    transaction do
      status = find_or_create_by!(instrument: instrument) { |s| s.is_on = false }
      where(id: status.id).lock.load
      is_on = yield
      update_all_shared_instruments(instrument, is_on: is_on) unless is_on.nil?
      status.reload
      status
    end
  end

  def as_json(_options = {})
    {
      instrument_status: {
        name: instrument.name,
        instrument_id: instrument.id,
        schedule_id: instrument.schedule_id,
        type: instrument.relay&.type,
        is_on: is_on?,
        error_message: @error_message,
        updated_at: updated_at&.iso8601,
      },
    }
  end

  def self.update_all_shared_instruments(instrument, is_on:)
    return unless instrument.relay&.networked_relay?

    shared_instruments = instrument.relay.shared_instruments
    return if shared_instruments.empty?

    valid_instruments = shared_instruments.select do |inst|
      inst.id.present? && inst.relay&.networked_relay?
    end

    return if valid_instruments.empty?

    instrument_ids = valid_instruments.map(&:id).sort # Sort to avoid deadlocks
    now = Time.current

    existing_statuses = where(instrument_id: instrument_ids).order(:instrument_id).lock.load
    existing_ids = existing_statuses.map(&:instrument_id)

    where(instrument_id: existing_ids).update_all(is_on:, updated_at: now) if existing_ids.any?

    missing_ids = instrument_ids - existing_ids

    return if missing_ids.empty?

    missing_ids.each do |inst_id|
      missing_instrument = valid_instruments.find { |inst| inst.id == inst_id }
      next unless missing_instrument

      status = find_or_initialize_by(instrument: missing_instrument)
      status.update!(is_on:, updated_at: now)
    end
  end

end
