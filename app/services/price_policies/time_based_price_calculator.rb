# frozen_string_literal: true

module PricePolicies

  class TimeBasedPriceCalculator

    attr_reader :price_policy

    delegate :product, to: :price_policy

    def initialize(price_policy)
      @price_policy = price_policy
    end

    def calculate(start_at, end_at, duration = nil)
      return if start_at.blank? && end_at.blank? && duration.blank?

      if duration.present?
        strategy_class(avoid_stepped: true).new(price_policy, start_at, end_at, duration:).calculate_estimate
      else
        return if start_at > end_at

        strategy_class.new(price_policy, start_at, end_at).calculate
      end
    end

    private

    def strategy_class(avoid_stepped: false)
      if product.daily_booking?
        Strategy::PerDay
      elsif !avoid_stepped && product.is_a?(Instrument) && product.duration_pricing_mode? && price_policy.duration_rates.present?
        Strategy::SteppedRate
      else
        Strategy::PerMinute
      end
    end

  end

end
