# frozen_string_literal: true

class DurationRate < ApplicationRecord

  SIXTY_MIN = 60.0

  belongs_to :price_policy, required: true

  validate :rate_or_subsidy
  validates :rate, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :subsidy, numericality: { greater_than: 0, allow_blank: true }
  validates :min_duration_hours, presence: true, numericality: { greater_than: 0, allow_blank: true }, uniqueness: { scope: :price_policy_id }
  validate :rate_lesser_than_or_equal_to_base_rate
  validate :subsidy_lesser_than_or_equal_to_base_rate

  scope :sorted, -> { order(min_duration_hours: :asc) }

  private

  def rate_or_subsidy
    if rate.blank? && subsidy.blank?
      errors.add(:base, "Either Rate or Adjustment must be provided")
    end
  end

  def rate_lesser_than_or_equal_to_base_rate
    return unless price_group.external? || price_group.master_internal?
    return unless price_policy.usage_rate && rate

    if rate / SIXTY_MIN > price_policy.usage_rate
      errors.add(:base, "Rate must be lesser than or equal to Base rate")
    end
  end

  def subsidy_lesser_than_or_equal_to_base_rate
    return if price_group.external? || price_group.master_internal?
    return unless price_policy.usage_rate && subsidy

    if subsidy / SIXTY_MIN > price_policy.usage_rate
      errors.add(:base, "Subsidy must be lesser than or equal to Base rate")
    end
  end

  def price_group
    price_policy.price_group
  end

end
