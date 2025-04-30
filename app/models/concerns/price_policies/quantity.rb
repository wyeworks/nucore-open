# frozen_string_literal: true

module PricePolicies

  module Quantity

    extend ActiveSupport::Concern

    included do
      validates :unit_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }, unless: :restrict_purchase?
      validates :unit_subsidy, numericality: { allow_blank: true, greater_than_or_equal_to: 0 }
    end

    def charge_for
      "quantity"
    end

    def calculate_cost_and_subsidy_from_order_detail(order_detail)
      calculate_cost_and_subsidy(order_detail.quantity)
    end

    def calculate_cost_and_subsidy(qty = 1)
      estimate_cost_and_subsidy(qty)
    end

    def estimate_cost_and_subsidy_from_order_detail(order_detail)
      estimate_cost_and_subsidy(order_detail.quantity)
    end

    def estimate_cost_and_subsidy(qty = 1)
      return nil if restrict_purchase?
      {
        cost: unit_cost * qty,
        subsidy: unit_subsidy * qty,
      }
    end

    def unit_total
      unit_cost - unit_subsidy
    end

    def estimate_cost_from_estimate_detail(estimate_detail)
      unit_cost * estimate_detail.quantity
    end

    private

    def rate_field
      :unit_cost
    end

    def subsidy_field
      :unit_subsidy
    end

  end

end
