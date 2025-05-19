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
    if product.nonbillable_mode?
      [PriceGroup.nonbillable]
    else
      [estimate.price_group].compact
    end
  end

  def assign_price_policy_and_cost
    if price_policy_id.present? && !price_policy
      self.price_policy = PricePolicy.find_by(id: price_policy_id)
    end
    
    pp = product.cheapest_price_policy(self, Time.current) if product.present?
    
    if pp.present?
      self.price_policy = pp
      
      if quantity.present?
        if product.is_a?(Instrument)
          if duration.present?
            pricing_params = { duration: duration }
            cost = pp.estimate_cost_and_subsidy_from_params(pricing_params)[:cost]
          end
        elsif product.respond_to?(:time_unit) && product.time_unit.present? && duration.present?
          cost_and_subsidy = pp.estimate_cost_and_subsidy(duration)
          cost = cost_and_subsidy[:cost] if cost_and_subsidy
        else
          cost_and_subsidy = pp.estimate_cost_and_subsidy(quantity)
          cost = cost_and_subsidy[:cost] if cost_and_subsidy
        end
        
        self.cost = cost || 0
      end
    end
    
    self.cost ||= 0
  end

  private

  def clear_duration_fields
    unless product.order_quantity_as_time? || product.is_a?(Instrument)
      self.duration = nil
      self.duration_unit = nil
    end
  end

  def price_policy_exists
    return if product.blank? || user.blank?

    pp = product.cheapest_price_policy(self, Time.current)
    if pp.blank?
      errors.add(:base, I18n.t("activerecord.errors.models.estimate_detail.no_price_policy"))
    end
  end
end
