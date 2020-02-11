# frozen_string_literal: true

class InstrumentStatus < ApplicationRecord

  belongs_to :instrument, inverse_of: :instrument_statuses

  validates_numericality_of :instrument_id
  alias_attribute :on, :is_on

  attr_accessor :error_message

  def as_json(_options = {})
    {
      instrument_status: {
        name: instrument.name,
        instrument_id: instrument.id,
        type: instrument.relay&.type,
        is_on: is_on?,
        error_message: @error_message,
      },
    }
  end

end
