# frozen_string_literal: true

class Estimate < ApplicationRecord
  belongs_to :facility, inverse_of: :estimates
  belongs_to :user
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by_id
  has_many :estimate_details, dependent: :destroy

  accepts_nested_attributes_for :estimate_details, allow_destroy: true, reject_if: :all_blank

  validate :expires_at_cannot_be_in_the_past
  validates :expires_at, presence: true

  def total_cost
    estimate_details.sum(&:cost)
  end

  private

  def expires_at_cannot_be_in_the_past
    if expires_at.blank? || expires_at < Time.zone.now
      errors.add(:expires_at, I18n.t("activerecord.errors.models.estimate.attributes.expires_at.in_the_past"))
    end
  end
end
