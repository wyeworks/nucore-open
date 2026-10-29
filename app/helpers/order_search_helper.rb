# frozen_string_literal: true

module OrderSearchHelper
  def order_detail_result_link(order_detail)
    path = if can_manage_order_detail? order_detail
             facility_order_path(order_detail.order.facility, order_detail.order)
           else
             order_order_detail_path(order_detail.order, order_detail)
           end
    link_to order_detail, path
  end

  private

  def can_manage_order_detail?(order_detail)
    ability = Ability.new(current_user, order_detail, controller)
    ability.can? :manage, order_detail
  end
end
