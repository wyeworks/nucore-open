# frozen_string_literal: true

# Defaults to the duration length of the reservation,
# but does not get auto-updated
class Accessories::Scaling::Manual < Accessories::Scaling::Default
  def update_quantity
    order_detail.quantity ||= order_detail.parent_order_detail.reservation.actual_or_current_duration_mins.to_i
  end

  def quantity_as_time?
    true
  end
end
