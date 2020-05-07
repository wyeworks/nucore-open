# frozen_string_literal: true

class AutoLogout

  def perform
    order_details.find_each do |od|
      next unless should_auto_logout?(od)

      od.transaction do
        logout_and_move_to_problem_queue(od)
      end
    end
  end

  private

  def order_details
    OrderDetail.purchased_active_reservations
               .merge(Reservation.relay_in_progress)
               .where("reserve_end_at < ?", Time.zone.now)
               .includes(:product)
               .readonly(false)
  end

  def should_auto_logout?(order_detail)
    reserve_end_at = order_detail.reservation.reserve_end_at
    relay = order_detail.product.relay
    auto_logout_minutes = relay.try(:auto_logout_minutes)

    configured = [
      reserve_end_at,
      auto_logout_minutes,
      relay.try(:auto_logout),
    ].all?

    configured && (reserve_end_at < auto_logout_minutes.minutes.ago)
  end

  def logout_and_move_to_problem_queue(order_detail)
    reservation = order_detail.reservation
    reservation.product.relay.deactivate unless reservation.other_reservation_using_relay?
    MoveToProblemQueue.move!(order_detail, cause: :auto_logout)
  rescue => e
    ActiveSupport::Notifications.instrument("background_error",
                                            exception: e, information: "Error on Order # #{order_detail} - #{e}")
    raise ActiveRecord::Rollback
  end

end
