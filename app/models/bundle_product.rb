# frozen_string_literal: true

class BundleProduct < ApplicationRecord

  belongs_to :bundle, foreign_key: :bundle_product_id
  belongs_to :product

  delegate :quantity_as_time?, to: :product

  validates_presence_of     :bundle_product_id, :product_id
  validates_numericality_of :quantity, only_integer: true, greater_than: 0
  validates_uniqueness_of   :product_id, scope: [:bundle_product_id]

  scope :alphabetized, -> { joins(:product).order(Arel.sql("LOWER(products.name)")) }

  # TODO: favor the alphabetized scope over relying on Array#sort
  def <=>(other)
    product.name <=> other.product.name
  end

end
