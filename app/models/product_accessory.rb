class ProductAccessory < ActiveRecord::Base

  SCALING_TYPES = {
    item: ["quantity"],
    service: ["quantity"],
    timed_service: ["manual", "auto"],
  }.with_indifferent_access

  ## relationships
  belongs_to :product
  belongs_to :accessory, class_name: "Product", foreign_key: :accessory_id

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

    errors.add(:scaling_type, "does not match product type")
  end

  def soft_delete
    update_attribute :deleted_at, Time.zone.now
  end

  def deleted?
    deleted_at.present?
  end

end
