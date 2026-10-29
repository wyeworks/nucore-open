# frozen_string_literal: true

class PriceGroupProduct < ApplicationRecord
  DEFAULT_RESERVATION_WINDOW = 14

  belongs_to :price_group
  belongs_to :product
  validates :price_group_id, :product_id, presence: true
  validates :reservation_window, presence: { if: proc { |pgp| pgp.product.is_a? Instrument } }
end
