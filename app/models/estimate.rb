# frozen_string_literal: true

class Estimate < ApplicationRecord
  belongs_to :facility, inverse_of: :estimates
  belongs_to :user
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_id
  has_many :estimate_details, dependent: :destroy

  accepts_nested_attributes_for :estimate_details, allow_destroy: true, reject_if: :all_blank

  validate :expires_at_cannot_be_in_the_past
  validates :expires_at, presence: true
  validate :validate_estimate_details

  def total_cost
    estimate_details.sum(&:cost)
  end

  private

  def expires_at_cannot_be_in_the_past
    return if expires_at.blank?

    if expires_at < Time.zone.now
      errors.add(:expires_at, I18n.t("activerecord.errors.models.estimate.attributes.expires_at.in_the_past"))
    end
  end

  def validate_estimate_details
    estimate_details.each do |estimate_detail|
      next if estimate_detail.marked_for_destruction?
      next if estimate_detail.valid?

      errors.delete(:"estimate_details.base")
      estimate_detail.errors.each do |error|
        errors.add(:base, "#{estimate_detail.product.name}: #{error.message}")
      end
    end
  end
end
