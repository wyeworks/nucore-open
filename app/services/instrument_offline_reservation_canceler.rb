# frozen_string_literal: true

class InstrumentOfflineReservationCanceler
  def cancel!
    Reservation.upcoming_offline(Time.current).each do |reservation|
      reservation.transaction do
        cancel_reservation(reservation)
        OfflineCancellationMailer.send_notification(reservation).deliver_later
      end
    end
  end

  private

  def admin_user
    # OrderDetail#cancel_reservation needs an object that responds to #id
    @admin_user ||= OpenStruct.new(id: 0)
  end

  def cancel_reservation(reservation)
    reservation.order_detail.cancel_reservation(admin_user, admin: true, canceled_reason: "The instrument was offline")
  end
end
