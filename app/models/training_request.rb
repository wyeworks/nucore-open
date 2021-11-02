# frozen_string_literal: true

class TrainingRequest < ApplicationRecord

  belongs_to :user
  belongs_to :product

  validates_presence_of :user, :product
  validates :user_id, uniqueness: { scope: :product_id, case_sensitive: false }

  validates_with ProductRequiresApprovalValidator

  def self.submitted?(user, product)
    where(product_id: product.id, user_id: user.id).present?
  end

  def self.from_product_user(product_user)
    where(user_id: product_user.user_id, product_id: product_user.product_id)
  end

end
