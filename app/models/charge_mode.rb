# frozen_string_literal: true

class ChargeMode
  def self.for_order_detail(order_detail)
    if order_detail.price_policy
      order_detail.price_policy.charge_for
    else
      current_policy = order_detail.product.current_price_policies.first
      current_policy.try(:charge_for)
    end
  end
end
