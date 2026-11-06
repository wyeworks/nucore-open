# frozen_string_literal: true

class TrainingRequest < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :note_updated_by, class_name: "User", optional: true

  validates :user, :product, presence: true
  validates :user_id, uniqueness: { scope: :product_id, case_sensitive: false }
  validates :note, length: { maximum: 1000, allow_blank: true }

  validates_with ProductRequiresApprovalValidator

  def update_note(note, user)
    self.note = note

    if note_changed?
      self.note_updated_by = user
      self.note_updated_at = Time.current
    end

    save
  end

  def self.submitted?(user, product)
    where(product_id: product.id, user_id: user.id).present?
  end

  def self.from_product_user(product_user)
    where(user_id: product_user.user_id, product_id: product_user.product_id)
  end
end
