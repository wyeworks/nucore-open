class ProductDisplayGroupProduct < ApplicationRecord
  belongs_to :product_display_group, inverse_of: :product_display_group_products, optional: false
  belongs_to :product, optional: false

  scope :sorted, -> { order(:position) }

  validate :validate_product_uniqueness

  private

  def validate_product_uniqueness
    return if product.blank?

    errors.add(:product_id, :taken, product: product.name) if self.class.where(product_id:).exists?
  end
end
