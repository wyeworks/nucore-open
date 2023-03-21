# frozen_string_literal: true

module PricePolicies

  class TimeBasedPriceCalculator

    attr_reader :price_policy

    delegate :usage_rate, :usage_subsidy, :minimum_cost, :minimum_cost_subsidy,
             :product, to: :price_policy

    def initialize(price_policy)
      @price_policy = price_policy
    end

    def calculate(start_at, end_at)
      return if start_at > end_at
      duration_mins = TimeRange.new(start_at, end_at).duration_mins
      discount_multiplier = calculate_discount(start_at, end_at)
      cost_and_subsidy(duration_mins, discount_multiplier)
    end

    def calculate_discount(start_at, end_at)
      discount = product.schedule_rules.to_a.sum do |sr|
        sr.discount_for(start_at, end_at, price_policy.price_group)
      end

      1 - (discount / 100)
    end

    private

    def cost_and_subsidy(duration_mins, discount_multiplier)
      costs = { cost: duration_mins * usage_rate * discount_multiplier }

      if costs[:cost] < minimum_cost.to_f
        { cost: minimum_cost, subsidy: minimum_cost_subsidy }
      else
        costs.merge(subsidy: duration_mins * usage_subsidy * discount_multiplier)
      end
    end

  end

end
