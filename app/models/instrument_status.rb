# frozen_string_literal: true

class InstrumentStatus < ApplicationRecord

  belongs_to :instrument, inverse_of: :instrument_status

  validates_numericality_of :instrument_id

  alias_attribute :on, :is_on

  attr_accessor :error_message

  def self.set_status_for(instrument, is_on:)
    transaction do
      instrument_ids = shared_instrument_ids(instrument)

      statuses = instrument_ids.map do |inst_id|
        find_or_create_by!(instrument_id: inst_id) { |s| s.is_on = false }
      end

      update_all_shared_instruments(instrument_ids, is_on:)

      # Reload all statuses to get the updated values and return them all
      statuses.each(&:reload)
      statuses
    end
  end

  def self.with_lock_for(instrument)
    transaction do
      instrument_ids = shared_instrument_ids(instrument)

      statuses = instrument_ids.map do |inst_id|
        find_or_create_by!(instrument_id: inst_id) { |s| s.is_on = false }
      end

      where(id: statuses.map(&:id)).order(:id).lock.load

      is_on = yield
      update_all_shared_instruments(instrument_ids, is_on:) unless is_on.nil?

      statuses.each(&:reload)
      statuses
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

  def self.update_all_shared_instruments(instrument_ids, is_on:)
    return if instrument_ids.empty?

    now = Time.current

    where(instrument_id: instrument_ids).update_all(is_on:, updated_at: now)
  end

  def self.shared_instrument_ids(instrument)
    return [instrument.id] unless instrument.relay&.networked_relay?

    shared_instruments = instrument.relay.shared_instruments
    return [] if shared_instruments.empty?

    valid_instruments = shared_instruments.select do |inst|
      inst.id.present? && inst.relay&.networked_relay?
    end

    valid_instruments.map(&:id).sort # Sort to avoid deadlocks
  end

end
