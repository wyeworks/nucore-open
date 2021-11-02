# frozen_string_literal: true

class OrderUncanceler

  def initialize
    @complete_status = OrderStatus.complete
    @canceled_status = OrderStatus.canceled
  end

  def uncancel_to_complete(order_detail)
    unless order_detail.canceled?
      Rails.logger.info "OrderDetail #{order_detail} was not in canceled state"
      return
    end

    order_detail.transaction do
      begin
        fulfilled_at = Time.zone.now

        if order_detail.reservation
          fulfilled_at = order_detail.reservation.reserve_end_at
          order_detail.reservation.update!(
            actual_start_at: order_detail.reservation.reserve_start_at,
            actual_end_at: order_detail.reservation.reserve_end_at)
        end

        order_detail.update!(
          canceled_by: nil,
          canceled_at: nil,
          canceled_reason: nil,
          order_status: @complete_status,
          state: "complete",
          fulfilled_at: fulfilled_at)

        order_detail.assign_price_policy
        order_detail.save!
        Rails.logger.info "OrderDetail #{order_detail} was uncanceled"
        true
      rescue => e
        Rails.logger.info "Could not save OrderDetail #{order_detail} because #{e.message}"
        raise ActiveRecord::Rollback
      end
    end
  end

end
