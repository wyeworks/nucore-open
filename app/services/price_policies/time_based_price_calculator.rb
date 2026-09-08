# frozen_string_literal: true

module PricePolicies
  class TimeBasedPriceCalculator
    attr_reader :price_policy

    delegate :product, to: :price_policy

    def initialize(price_policy)
      @price_policy = price_policy
    end

    def calculate(...)
      strategy_class.new(price_policy, ...).calculate
    end

    private

    def strategy_class
      if product.daily_booking?
        Strategy::PerDay
      elsif product.duration_pricing_mode?
        Strategy::SteppedRate
      else
        Strategy::PerMinute
      end
    end
  end
end
