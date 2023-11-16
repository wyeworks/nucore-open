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

      if product.is_a?(Instrument) && product.duration_pricing_mode? && price_policy.duration_rates.present?
        duration_pricing_cost_and_subsidy(duration_mins)
      else
        discount_multiplier = calculate_discount(start_at, end_at)
        cost_and_subsidy(duration_mins, discount_multiplier)
      end
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

    def duration_pricing_cost_and_subsidy(duration_mins)
      duration_in_hours = duration_mins / 60.0

      result = build_intervals.reduce({ time_left: duration_in_hours, cost: 0, subsidy: 0 }) do |acc, interval_data|
        time_left = acc[:time_left]

        interval_length = interval_data[:interval_end] - interval_data[:interval_start]

        time_to_charge = [time_left, interval_length].min

        acc[:time_left] -= time_to_charge
        acc[:cost] += (interval_data[:step_rate] || 0) * time_to_charge
        acc[:subsidy] += (interval_data[:step_subsidy] || 0) * time_to_charge

        acc
      end

      { cost: result[:cost], subsidy: result[:subsidy] }
    end

    def build_intervals
      sorted_duration_rates = price_policy.duration_rates.sorted
      sorted_subsidies = sorted_duration_rates.map { |dr| dr.subsidy || 0 }

      default_rate = usage_rate * 60
      default_subsidy = usage_subsidy * 60

      intervals = [
        {
          interval_start: 0,
          interval_end: sorted_duration_rates[0]&.min_duration_hours || Float::INFINITY,
          step_rate: default_rate,
          step_subsidy: default_subsidy
        }
      ]

      sorted_duration_rates.each_with_index do |duration_rate, index|
        if duration_rate.rate.present?
          hourly_rate = duration_rate.rate
          hourly_subsidy = nil
        else
          hourly_rate = default_rate
          # The subsidy for the current interval is the sum of the subsidies of all the previous intervals
          hourly_subsidy = sorted_subsidies.slice(0, index+1).sum(default_subsidy)
        end

        interval_start = duration_rate.min_duration_hours
        interval_end = sorted_duration_rates[index + 1]&.min_duration_hours || Float::INFINITY

        intervals << { interval_start: , interval_end:, step_rate: hourly_rate, step_subsidy: hourly_subsidy }
      end

      intervals
    end

  end

end
