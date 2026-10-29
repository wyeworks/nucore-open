# frozen_string_literal: true

class InstrumentAlert < ApplicationRecord
  belongs_to :instrument, inverse_of: :alert

  validates :note, presence: true, length: { maximum: 256 }
end
