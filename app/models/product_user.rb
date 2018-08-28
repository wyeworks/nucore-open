# frozen_string_literal: true

class ProductUser < ApplicationRecord

  belongs_to :user
  belongs_to :product
  belongs_to :product_access_group
  belongs_to :approved_by_user, class_name: "User", foreign_key: "approved_by", inverse_of: false

  validates_numericality_of :product_id, :user_id, :approved_by, only_integer: true
  validates_uniqueness_of :user_id, scope: :product_id, message: "is already approved"

  before_create ->(product_user) { product_user.approved_at = Time.zone.now }

end
