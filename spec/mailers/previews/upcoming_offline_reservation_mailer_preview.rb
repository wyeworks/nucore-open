# frozen_string_literal: true

class UpcomingOfflineReservationMailerPreview < ActionMailer::Preview
  def upcoming_offline_reservation
    UpcomingOfflineReservationMailer
      .send_offline_instrument_warning(Reservation.user.first)
  end
end
