# frozen_string_literal: true

module PricePolicies

  module Strategy

    class BaseStrategy
      attr_reader :price_policy, :start_at, :end_at, :handle_minimum_cost

      delegate :minimum_cost,
               :minimum_cost_subsidy,
               :product,
               to: :price_policy

      def initialize(price_policy, start_at: nil, end_at: nil, duration: nil, minimum_cost: true)
        @price_policy = price_policy
        @start_at = start_at
        @end_at = end_at
        @raw_duration = duration
        @handle_minimum_cost = minimum_cost

        if [start_at, end_at, duration].all?(&:nil?)
          raise ArgumentError, "Must specify start_at, end_at or duration"
        end

        if [start_at, end_at].all?(&:present?) && start_at > end_at
          raise ArgumentError, "Wrong arguments: start_at > end_at"
        end
      end

      # Calculate cost and subsidy based on price policy
      #
      # return a Hash { cost: float, subsidy: float }
      def calculate
        raise NotImplementedError
      end

      def duration
        @raw_duration || time_duration
      end

      def time_duration
        time_range.duration_mins
      end

      protected

      def with_discount(costs)
        costs.transform_values { |value| value * discount_factor }
      end

      def with_minimum_cost(costs)
        if costs[:cost] < minimum_cost.to_f
          { cost: minimum_cost, subsidy: minimum_cost_subsidy }
        else
          costs
        end
      end

      def time_range
        @time_range ||= TimeRange.new(start_at, end_at)
      end

      def discount_factor
        1 - (discount / 100)
      end

      def discount
        @discount ||=
          if @raw_duration.present?
            0.0
          else
            product.schedule_rules.to_a.sum do |schedule_rule|
              schedule_rule.discount_for(start_at, end_at, price_policy.price_group)
            end
          end
      end
    end

    # Charge usage per minute
    #
    # Applies subsidy and discounts
    class PerMinute < BaseStrategy
      delegate :usage_rate,
               :usage_subsidy,
               to: :price_policy

      def calculate
        costs = {
          cost: duration * usage_rate,
          subsidy: duration * usage_subsidy,
        }

        costs = with_discount(costs)

        handle_minimum_cost ? with_minimum_cost(costs) : costs
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
        {
          cost: duration * usage_rate_daily,
          subsidy: duration * usage_subsidy_daily.to_f,
        }
      end

      def time_duration
        time_range.duration_days.ceil
      end
    end

    # Charge usage per minute with a stepped (or tiered) rate
    #
    # If price policy does not have rates then it's equivalent to PerMinute
    class SteppedRate < BaseStrategy
      delegate :usage_rate, :usage_subsidy, to: :price_policy

      def calculate
        costs = cost_and_subsidy_for(duration)
        costs = with_discount(costs)

        handle_minimum_cost ? with_minimum_cost(costs) : costs
      end

      private

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

      def cost_and_subsidy_for(total_mins)
        result = build_intervals.reduce({ time_left: total_mins, cost: 0, subsidy: 0 }) do |acc, interval_data|
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
    end

  end

end
