# frozen_string_literal: true

class EstimateDetail < ApplicationRecord
  TIME_UNITS = %w[mins days].freeze

  belongs_to :estimate, inverse_of: :estimate_details
  belongs_to :product
  belongs_to :price_policy

  after_validation :set_price_policy, if: -> { recalculate || price_policy_id.nil? }

  before_save :clear_duration_fields

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :duration, numericality: { greater_than: 0 }, allow_nil: true
  validates :duration_unit, inclusion: { in: TIME_UNITS }, allow_nil: true

  delegate :user, to: :estimate

  # Used to trigger before_update callback
  attribute :recalculate

  def price_groups
    if product.nonbillable_mode?
      [PriceGroup.nonbillable]
    else
      [estimate.price_group].compact
    end
  end

  def set_price_policy
    return if errors.present?

    price_policy = product.cheapest_price_policy(self, Time.current)

    if price_policy.blank?
      errors.add(:base, :no_price_policy)

      false
    else
      self.price_policy = price_policy
      self.cost = price_policy.estimate_cost_from_estimate_detail(self)

      true
    end
  end

  private

  def clear_duration_fields
    unless product.order_quantity_as_time? || product.is_a?(Instrument)
      self.duration = nil
      self.duration_unit = nil
    end
  end
end
