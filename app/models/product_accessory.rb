# frozen_string_literal: true

class ProductAccessory < ApplicationRecord
  SCALING_TYPES = {
    item: ["quantity"],
    service: ["quantity"],
    timed_service: ["manual", "auto"],
  }.with_indifferent_access
  SCALING_TYPES.default = ["quantity"]

  ## relationships
  belongs_to :product
  belongs_to :accessory, class_name: "Product"

  ## validations
  validates :product, presence: true
  validates :accessory, presence: true
  validates :scaling_type, presence: true
  validate :scaling_type_matches_product

  def self.scaling_types
    SCALING_TYPES.values.flatten.uniq
  end

  def scaling_type_matches_product
    return if SCALING_TYPES[accessory.type.underscore].include?(scaling_type)

    errors.add(:scaling_type)
  end

  def soft_delete
    update_attribute :deleted_at, Time.zone.now
  end
end
