# frozen_string_literal: true

module TransactionSearch

  class NPlusOneOptimizer < BaseOptimizer

    def optimize
      order_details.includes(order: [:user, :facility])
                   .includes(:account, :product, :order_status, :statement)
                   .includes(:reservation)
                   .includes(:bundle)
                   .preload(account: :owner_user)
    end

  end

end
