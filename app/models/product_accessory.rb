class ProductAccessory < ActiveRecord::Base

  SCALING_TYPES = %w(quantity manual auto).freeze

  ## relationships
  belongs_to :product
  belongs_to :accessory, class_name: "Product", foreign_key: :accessory_id

  ## validations
  validates :product, presence: true
  validates :accessory, presence: true
  validates :scaling_type, presence: true, inclusion: SCALING_TYPES

  def self.scaling_types
    SCALING_TYPES
  end

  def soft_delete
    update_attribute :deleted_at, Time.zone.now
  end

  def deleted?
    deleted_at.present?
  end

end
