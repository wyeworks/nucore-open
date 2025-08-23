# frozen_string_literal: true

module TransactionSearch

  class NPlusOneOptimizer < BaseOptimizer

    def optimize
      result = order_details.includes(order: :user)
                            .includes(:reservation)
                            .preload(:bundle)

      if SettingsHelper.feature_on?(:billing_table_price_groups)
        result = result.includes(account: [:price_group_members, :owner_user])
                       .preload(account: { price_group_members: :price_group })
      end

      result
    end

  end

end
