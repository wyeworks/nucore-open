# frozen_string_literal: true

class BundleProduct < ApplicationRecord
  belongs_to :bundle, foreign_key: :bundle_product_id
  belongs_to :product

  delegate :quantity_as_time?, to: :product

  validates :bundle_product_id, :product_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :quantity, numericality: { less_than: 10, if: :timed_service_product? }
  validates :product_id, uniqueness: { scope: [:bundle_product_id] }

  scope :alphabetized, -> { joins(:product).order(Arel.sql("LOWER(products.name)")) }

  # TODO: favor the alphabetized scope over relying on Array#sort
  def <=>(other)
    product.name <=> other.product.name
  end

  def timed_service_product?
    product.is_a?(TimedService)
  end
end
