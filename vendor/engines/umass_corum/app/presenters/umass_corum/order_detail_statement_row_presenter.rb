# frozen_string_literal: true

module UmassCorum

  class OrderDetailStatementRowPresenter < SimpleDelegator

    include DateHelper
    include ActionView::Helpers::NumberHelper

    def order_detail
      __getobj__
    end

    def to_row
      [
        quantity,
        format_usa_date(order_detail.fulfilled_at),
        order_detail.to_s,
        description,
        unit_of_measure,
        hourly_rate,
        total_amount,
      ]
    end

    def quantity
      if order_detail.time_data.present? && order_detail.time_data.respond_to?(:billable_minutes) && !order_detail.product.daily_booking?
        minutes = if order_detail.canceled_reason && order_detail.complete?
                    nil
                  else
                    order_detail.time_data.billable_duration_mins
                  end
        QuantityPresenter.new(order_detail.product, minutes).to_s if minutes
      elsif order_detail.product.daily_booking?
        QuantityPresenter.new(order_detail.product, order_detail.reservation.duration_days).to_s
      else
        QuantityPresenter.new(order_detail.product, order_detail.quantity).to_s
      end
    end

    def description
      [order_detail.product, normalize_whitespace(order_detail.note)].map(&:presence).compact.join("\n")
    end

    def normalize_whitespace(text)
      WhitespaceNormalizer.normalize(text)
    end

    def unit_of_measure
      if order_detail.product.quantity_as_time?
        order_detail.product.daily_booking? ? "day" : "hr"
      else
        ""
      end
    end

    def hourly_rate
      price_policy = order_detail.price_policy
      if price_policy.try(:has_rate?)
        number_to_currency(price_policy.subsidized_hourly_usage_cost)
      elsif price_policy.try(:has_daily_rate?)
        number_to_currency(price_policy.subsidized_daily_usage_cost)
      else
        number_to_currency(price_policy.unit_total)
      end
    end

    def total_amount
      if order_detail.price_change_reason.present?
        "adjusted: #{number_to_currency(order_detail.actual_total)}"
      else
        number_to_currency(order_detail.actual_total)
      end
    end

  end

end
