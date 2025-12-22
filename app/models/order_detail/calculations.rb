# frozen_string_literal: true

class OrderDetail
  module Calculations
    extend ActiveSupport::Concern

    module ClassMethods
      def with_actual_costs
        where.not(actual_cost: nil).where.not(actual_subsidy: nil)
      end

      ##
      # Grand total of a set of order detail
      # taken to be the sum of actual_total || estimated_total for each
      # record
      def grand_total
        ac = merge(OrderDetail.with_actual_costs).sum("actual_cost - actual_subsidy")
        ac += merge(OrderDetail.with_actual_costs.invert_where).sum("estimated_cost - estimated_subsidy")
        ac
      end
    end
  end
end
