# frozen_string_literal: true

class InstrumentStatus < ApplicationRecord

  belongs_to :instrument, inverse_of: :instrument_status

  validates_numericality_of :instrument_id

  alias_attribute :on, :is_on

  attr_accessor :error_message

  def self.set_status_for(instrument, is_on:)
    status = find_or_initialize_by(instrument: instrument)
    status.update!(is_on: is_on, updated_at: Time.current)
    status
  end

  # Locks the instrument status row before executing the block.
  def self.with_lock_for(instrument)
    transaction do
      # Create with default is_on if not exists, then lock the row
      status = find_or_create_by!(instrument: instrument) { |s| s.is_on = false }
      status.lock!
      is_on = yield
      status.update!(is_on: is_on, updated_at: Time.current) unless is_on.nil?
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

end
