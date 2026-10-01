# frozen_string_literal: true

class EstimateDetailPresenter < SimpleDelegator
  include ActionView::Helpers::NumberHelper

  def product_display
    parts = [product.name]

    if product.facility != estimate.facility
      parts << "(#{product.facility.name})"
    end

    parts.join(" ")
  end

  def duration_display
    return duration if duration_mins?

    duration_with_unit if duration_days?
  end

  def duration_with_unit
    return if duration.blank? || duration_unit.blank?

    [duration, EstimateDetail.duration_unit_label(duration_unit, count: duration)].join(" ")
  end

  def unit_cost_display
    number_to_currency(price_policy&.unit_net_cost)
  end

  def cost_display
    number_to_currency(cost)
  end

  def duration_mins?
    duration_unit == "mins"
  end

  def duration_days?
    duration_unit == "days"
  end
end
