# frozen_string_literal: true

class PriceGroupDiscount < ApplicationRecord
  belongs_to :price_group
  belongs_to :schedule_rule

  validates :discount_percent, presence: true
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than: 100 }
end
