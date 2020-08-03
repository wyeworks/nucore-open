# frozen_string_literal: true

class OfflineCancellationMailer < ApplicationMailer

  include OfflineReservationArguments

  attr_reader :reservation

  def send_notification(reservation)
    @reservation = reservation
    @instrument = reservation.product
    mail(to: reservation.user.email, subject: subject)
  end

  private

  def subject
    text(
      "views.offline_cancellation_mailer.send_notification.subject",
      product: reservation.product,
    )
  end

end
