# frozen_string_literal: true

class TimedServicePricePolicy < PricePolicy

  include PricePolicies::Usage

  def estimate_cost_and_subsidy_from_order_detail(order_detail)
    return if order_detail.quantity.blank?

    estimate_cost_and_subsidy(order_detail.quantity)
  end

  def calculate_cost_and_subsidy_from_order_detail(order_detail)
    calculate_for_time(order_detail.quantity)
  end

  def estimate_cost_and_subsidy(duration)
    calculate_for_time(duration)
  end

  def charge_for
    "minutes"
  end

  def estimate_cost_from_estimate_detail(estimate_detail)
    cost_for_one = calculate_for_time(estimate_detail.duration)[:cost]

    cost_for_one * estimate_detail.quantity
  end

  private

  def calculate_for_time(duration)
    return if restrict_purchase?

    costs = { cost: duration * usage_rate, subsidy: duration * usage_subsidy }
  end

end
