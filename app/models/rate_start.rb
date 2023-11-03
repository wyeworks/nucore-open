# frozen_string_literal: true

class RateStart < ApplicationRecord

  has_many :duration_rates
  belongs_to :instrument, foreign_key: :product_id

  validates :min_duration, presence: true
  validates :min_duration, numericality: { greater_than: 0, allow_blank: true }

end
