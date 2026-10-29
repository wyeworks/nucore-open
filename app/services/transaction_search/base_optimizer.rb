# frozen_string_literal: true

module TransactionSearch
  class BaseOptimizer
    attr_reader :order_details

    def initialize(order_details)
      @order_details = order_details
    end

    def optimize
      raise NotImplementedError
    end
  end
end
