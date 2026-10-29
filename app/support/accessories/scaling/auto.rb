# frozen_string_literal: true

# defaults to the duration length of the reservation
# and auto-updates if the duration changes
class Accessories::Scaling::Auto < Accessories::Scaling::Default
  def update_quantity
    order_detail.quantity = order_detail.parent_order_detail.reservation.actual_or_current_duration_mins.to_i
  end

  def quantity_editable?
    false
  end

  def quantity_as_time?
    true
  end
end
