# frozen_string_literal: true

class DurationRate < ApplicationRecord

  SIXTY_MIN = 60.0

  belongs_to :price_policy, required: true

  validates :rate, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0 }
  validates :subsidy, presence: { message: ->(object, _data) { "^Missing subsidy for #{object.price_group.name}" } }, if: -> { requires_subsidy? }
  validates :subsidy, numericality: { greater_than_or_equal_to: 0, allow_blank: true }
  validates :min_duration_hours,
    presence: { message: ->(object, _data) { "^Missing value for 'Rate start (hr)'" } },
    numericality: { greater_than: 0, allow_blank: true },
    uniqueness: { scope: :price_policy_id }
  validate :rate_lesser_than_or_equal_to_base_rate
  validate :subsidy_lesser_than_or_equal_to_rate

  scope :sorted, -> { order(min_duration_hours: :asc) }

  def rate=(hourly_rate)
    super
    self[:rate] /= SIXTY_MIN if self[:rate].respond_to? :/
  end

  def subsidy=(hourly_subsidy)
    super
    self[:subsidy] /= SIXTY_MIN if self[:subsidy].respond_to? :/
  end

  def hourly_rate
    rate.try :*, SIXTY_MIN
  end

  def hourly_subsidy
    subsidy.try :*, SIXTY_MIN
  end

  def subsidized_hourly_cost
    hourly_rate - hourly_subsidy
  end

  def price_group
    price_policy.price_group
  end

  def set_rate_from_base
    return unless requires_subsidy?
    return if rate.present?

    self.rate = price_policy.hourly_usage_rate
  end

  private

  def rate_lesser_than_or_equal_to_base_rate
    return unless price_policy.usage_rate && rate

    if rate > price_policy.usage_rate
      errors.add(:base, "Rate must be lesser than or equal to Base rate")
    end
  end

  def subsidy_lesser_than_or_equal_to_rate
    return unless requires_subsidy?
    return unless rate && subsidy

    if subsidy > rate
      errors.add(:base, "Subsidy must be lesser than or equal to step rate")
    end
  end

  def requires_subsidy?
    price_group.subsidy_only?
  end

end
