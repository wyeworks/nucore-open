# frozen_string_literal: true

class SecureRoomPricePolicy < PricePolicy

  include PricePolicies::Usage

  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    calculate_cost_and_subsidy_from_order_detail(order_detail)
  end

  def calculate_cost_and_subsidy_from_order_detail(order_detail)
    return unless order_detail.occupancy
    entry_at = order_detail.occupancy.entry_at
    exit_at = order_detail.occupancy.exit_at
    return unless entry_at && exit_at

    calculator.calculate(entry_at, exit_at)
  end

  def charge_for
    product.entry_only? ? "entry" : "usage"
  end

  def estimate_cost_from_estimate_detail(estimate_detail)
    # TODO: NUOPEN-227
  end

  private

  def calculator
    PricePolicies::TimeBasedPriceCalculator.new(self)
  end

end
