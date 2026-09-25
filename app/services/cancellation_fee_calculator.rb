# frozen_string_literal: true

class CancellationFeeCalculator

  attr_accessor :order_detail
  delegate :reservation, :product, :price_policy, to: :order_detail, allow_nil: true

  def initialize(original_order_detail)
    # Use a dupped version so that any changes don't get applied to the original
    @order_detail = original_order_detail.dup
    @order_detail.product = original_order_detail.product
    @order_detail.time_data = original_order_detail.time_data.dup
    @order_detail.price_policy = original_order_detail.price_policy
  end

  def costs
    return unless reservation && product.min_cancel_hours.to_i > 0

    return @costs if defined?(@costs)

    order_detail.canceled_at ||= Time.current
    order_detail.assign_price_policy unless order_detail.price_policy

    @costs = order_detail.price_policy&.calculate_cancellation_costs(reservation)
  end

  def total_cost
    return 0 unless costs
    costs[:cost] - costs[:subsidy]
  end

  def charge_full_price?
    costs # make sure costs has been initialized in case this gets called first
    order_detail.price_policy&.charge_full_price_on_cancellation?
  end

end
