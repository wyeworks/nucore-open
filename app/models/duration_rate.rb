# frozen_string_literal: true

class DurationRate < ApplicationRecord

  belongs_to :instrument, foreign_key: :product_id

  validates :min_duration, presence: true
  validates :min_duration, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :rate, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
end
