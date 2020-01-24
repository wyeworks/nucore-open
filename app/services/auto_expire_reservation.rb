# frozen_string_literal: true

class AutoExpireReservation

  def perform
    order_details.find_each do |order_detail|
      order_detail.transaction do
        expire_reservation(order_detail)
      end
    end
  end

  private

  def order_details
    purchased_active_order_details
  end

  def earliest_allowed_time
    Settings.reservations.timeout_period.seconds.ago
  end

  def purchased_active_order_details
    OrderDetail.purchased_active_reservations
               .joins(:product)
               .joins_relay
               .where("reservations.reserve_end_at < ?", earliest_allowed_time)
               .readonly(false)
  end

  def expire_reservation(order_detail)
    MoveToProblemQueue.move!(order_detail)

    # fulfilled_at gets set to Time.current but we want it to be the end of the reservation
    order_detail.update!(fulfilled_at: order_detail.reservation.reserve_end_at)
  rescue => e
    ActiveSupport::Notifications.instrument("background_error",
                                            exception: e, information: "Failed expire reservation order detail ##{order_detail}")
    raise ActiveRecord::Rollback
  end

end
