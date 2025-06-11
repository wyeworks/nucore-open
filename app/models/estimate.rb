# frozen_string_literal: true

class Estimate < ApplicationRecord
  belongs_to :facility, inverse_of: :estimates
  belongs_to :user, optional: true
  belongs_to :price_group
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_id
  has_many :estimate_details, dependent: :destroy

  accepts_nested_attributes_for :estimate_details, allow_destroy: true, reject_if: :all_blank

  before_save :clear_custom_name_field

  validate :expires_at_cannot_be_in_the_past
  validates :expires_at, presence: true
  validate :user_or_custom_name_present

  def user_display_name
    user&.full_name || custom_name
  end

  def total_cost
    estimate_details.sum(&:cost)
  end

  def duplicate(created_by_user)
    duplicated_estimate = dup
    duplicated_estimate.created_by_id = created_by_user.id
    duplicated_estimate.expires_at = 1.month.from_now

    duplicated_estimate.description = "Copy of #{description.presence || id}"

    details_to_copy = estimate_details.map(&:dup)

    details_to_copy.each do |detail|
      duplicated_estimate.estimate_details << detail
    end

    duplicated_estimate.save! if duplicated_estimate.valid?

    duplicated_estimate
  end

  def recalculate
    success = true

    transaction do
      if estimate_details.all?(&:assign_price_policy_and_cost)
        save!
      else
        success = false
      end
    rescue ActiveRecord::RecordInvalid
      success = false
      raise ActiveRecord::Rollback
    end

    success
  end

  private

  def expires_at_cannot_be_in_the_past
    return if expires_at.blank?

    if expires_at < Time.zone.now
      errors.add(:expires_at, I18n.t("activerecord.errors.models.estimate.attributes.expires_at.in_the_past"))
    end
  end

  def user_or_custom_name_present
    if user_id.blank? && custom_name.blank?
      errors.add(:base, I18n.t("activerecord.errors.models.estimate.attributes.base.user_or_custom_name_required"))
    end
  end

  def clear_custom_name_field
    self.custom_name = nil if user_id.present?
  end
end
