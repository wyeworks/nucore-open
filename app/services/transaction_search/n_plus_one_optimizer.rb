# frozen_string_literal: true

module TransactionSearch

  class NPlusOneOptimizer < BaseOptimizer

    def optimize
      order_details.includes(order: :user)
                   .includes(:reservation)
                   .preload(:bundle)
    end

  end

end
