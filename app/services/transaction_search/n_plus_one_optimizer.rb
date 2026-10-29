# frozen_string_literal: true

module TransactionSearch
  class NPlusOneOptimizer < BaseOptimizer
    def optimize
      result = order_details.includes(order: :user)
                            .includes(:reservation)
                            .preload(:bundle)

      result = result.includes(price_policy: :price_group) if SettingsHelper.feature_on?("billing.billing_table_price_groups")

      result
    end
  end
end
