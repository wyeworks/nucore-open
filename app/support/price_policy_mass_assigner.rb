# frozen_string_literal: true

class PricePolicyMassAssigner
  def self.assign_price_policies(order_details)
    order_details.select do |order_detail|
      if order_detail.assign_price_policy
        order_detail.save
      else
        false
      end
    end
  end
end
