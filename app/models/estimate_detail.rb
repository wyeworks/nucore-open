# frozen_string_literal: true

class EstimateDetail < ApplicationRecord
  TIME_UNITS = %w[mins days].freeze

  belongs_to :estimate, inverse_of: :estimate_details
  belongs_to :product
  belongs_to :price_policy

  before_save :clear_duration_fields
  before_save :assign_price_policy_and_cost

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :duration, numericality: { greater_than: 0 }, allow_nil: true
  validates :duration_unit, inclusion: { in: TIME_UNITS }, allow_nil: true
  validate :price_policy_exists

  delegate :user, to: :estimate

  def price_groups
    return [PriceGroup.nonbillable] if product.nonbillable_mode?

    return [] if user.blank?

    user.price_groups.uniq
  end

  private

  def clear_duration_fields
    unless product.order_quantity_as_time? || product.is_a?(Instrument)
      self.duration = nil
      self.duration_unit = nil
    end
  end

  def assign_price_policy_and_cost
    pp = product.cheapest_price_policy(self, Time.current)

    return if pp.blank?

    cost = pp.estimate_cost_from_estimate_detail(self)

    self.price_policy = pp
    self.cost = cost
  end

  def price_policy_exists
    return if product.blank? || user.blank?

    pp = product.cheapest_price_policy(self, Time.current)
    if pp.blank?
      errors.add(:base, I18n.t("activerecord.errors.models.estimate_detail.no_price_policy"))
    end
  end
end
