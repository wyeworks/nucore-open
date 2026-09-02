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
    if duration_mins?
      duration
    elsif duration_days?
      [
        duration,
        EstimateDetail.human_attribute_name(
          "duration_unit.days",
          count: duration,
        ),
      ].join(" ")
    end
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
