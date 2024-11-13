# frozen_string_literal: true

module PricePolicies

  module Strategy

    class BaseStrategy
      attr_reader :price_policy, :start_at, :end_at

      delegate :product, to: :price_policy

      def initialize(price_policy, start_at, end_at)
        @price_policy = price_policy
        @start_at = start_at
        @end_at = end_at
      end

      # Calculate cost and subsidy based on price policy
      #
      # return a Hash { cost: float, subsidy: float }
      def calculate
        raise NotImplementedError
      end

      protected

      def time_range
        @time_range ||= TimeRange.new(start_at, end_at)
      end
    end

    # Charge usage per minute
    #
    # Applies subsidy and discounts
    class PerMinute < BaseStrategy
      delegate :minimum_cost,
               :minimum_cost_subsidy,
               :usage_rate,
               :usage_subsidy,
               to: :price_policy

      delegate :duration_mins, to: :time_range

      def calculate
        costs = { cost: duration_mins * usage_rate * discount_factor }

        if costs[:cost] < minimum_cost.to_f
          { cost: minimum_cost, subsidy: minimum_cost_subsidy }
        else
          costs.merge(subsidy: duration_mins * usage_subsidy * discount_factor)
        end
      end

      def discount_factor
        discount = product.schedule_rules.to_a.sum do |sr|
          sr.discount_for(start_at, end_at, price_policy.price_group)
        end

        1 - (discount / 100)
      end
    end

    # Charge usage per day
    #
    # Days are counted the amount of 24 blocks
    # between start_at and end_at.
    #
    # Applies subsidy
    class PerDay < BaseStrategy
      delegate :usage_rate_daily, :usage_subsidy_daily, to: :price_policy

      def calculate
        subsidy = if price_policy.usage_subsidy_daily.present?
                    duration_days * price_policy.usage_subsidy_daily
                  end

        {
          subsidy: subsidy || 0,
          cost: duration_days * usage_rate_daily,
        }
      end

      def duration_days
        time_range.duration_days.ceil
      end
    end

    # Charge usage per minute with a stepped (or tiered) rate
    class SteppedRate < BaseStrategy
      delegate :usage_rate, :usage_subsidy, to: :price_policy
      delegate :duration_mins, to: :time_range

      def calculate
        result = build_intervals.reduce({ time_left: duration_mins, cost: 0, subsidy: 0 }) do |acc, interval_data|
          time_left = acc[:time_left]

          interval_length = (interval_data[:interval_end] - interval_data[:interval_start]) * 60

          time_to_charge = [time_left, interval_length].min

          acc[:time_left] -= time_to_charge
          acc[:cost] += (interval_data[:step_rate] || 0) * time_to_charge
          acc[:subsidy] += (interval_data[:step_subsidy] || 0) * time_to_charge

          acc
        end

        { cost: result[:cost], subsidy: result[:subsidy] }
      end

      def build_intervals
        intervals = [
          {
            interval_start: 0,
            interval_end: sorted_duration_rates[0]&.min_duration_hours || Float::INFINITY,
            step_rate: usage_rate,
            step_subsidy: usage_subsidy || 0,
          },
        ]

        sorted_duration_rates.each_with_index do |duration_rate, index|
          step_rate = duration_rate.rate
          step_subsidy = duration_rate.subsidy

          interval_start = duration_rate.min_duration_hours
          interval_end = sorted_duration_rates[index + 1]&.min_duration_hours || Float::INFINITY

          intervals << { interval_start:, interval_end:, step_rate:, step_subsidy: }
        end

        intervals
      end

      def sorted_duration_rates
        @sorted_duration_rates ||= price_policy.duration_rates.sorted
      end
    end

  end

end
