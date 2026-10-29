# frozen_string_literal: true

module SecureRooms
  class NPlusOneOccupancyOptimizer < TransactionSearch::BaseOptimizer
    def optimize
      order_details.includes(:occupancy)
    end
  end
end
