# frozen_string_literal: true

module OrdersHelper

  def display_cost_prefix_for_order(order)
    case
    when order.order_details.with_actual_costs.present?
      :actual
    when order.order_details.with_estimated_costs.present?
      :estimated
    else
      :unassigned
    end
  end

  def display_cost_prefix_for_order_detail(order_detail)
    case
    when order_detail.actual_cost
      :actual
    when order_detail.estimated_cost
      :estimated
    else
      :unassigned
    end
  end

  def show_price_breakdown?
    SettingsHelper.feature_off?("pricing.hide_subsidy_from_customers")
  end

  def show_note_input_to_user?(order_detail)
    acting_as? || order_detail.product.user_notes_field_mode.visible?
  end

end
