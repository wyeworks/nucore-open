# frozen_string_literal: true

class AutoEndPreviousReservation

  def initialize(product, current_user)
    @product = product
    @current_user = current_user
  end

  def end_previous_reservations!
    return unless SettingsHelper.feature_on?(:auto_end_reservations_on_next_start)
    return unless timer_based_instrument?

    reservations_to_end = previous_reservations

    reservations_to_end.each do |reservation|
      auto_end_reservation(reservation)
    end
  end

  private

  def timer_based_instrument?
    @product.control_mechanism == Relay::CONTROL_MECHANISMS[:timer] ||
      @product.control_mechanism == Relay::CONTROL_MECHANISMS[:relay]
  end

  def previous_reservations
    @product.reservations.joins(:order_detail)
            .where(actual_end_at: nil)
            .where(reserve_end_at: ...Time.current)
            .where(order_details: { canceled_at: nil })
            .where.not(actual_start_at: nil)
  end

  def auto_end_reservation(reservation)
    reservation.update!(actual_end_at: Time.current)
    reservation.order_detail.complete!

    # Send notification email to user whose reservation was auto-ended
    AutoEndReservationMailer.notify_auto_ended(reservation, @current_user).deliver_later

    LogEvent.log(reservation.order_detail, :auto_ended_by_next_reservation, @current_user,
                 metadata: { cause: :auto_end_on_next_start })
  end

end
