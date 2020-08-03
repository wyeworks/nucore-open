# frozen_string_literal: true

class UpcomingOfflineReservationMailer < ApplicationMailer

  include OfflineReservationArguments

  attr_reader :reservation

  def send_offline_instrument_warning(reservation)
    @reservation = reservation
    mail(to: recipient.email, subject: subject)
  end

  private

  def recipient
    reservation.user
  end

  def subject
    text("views.upcoming_offline_reservation_mailer.subject",
         instrument: reservation.product)
  end

end
