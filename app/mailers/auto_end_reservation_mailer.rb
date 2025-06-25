# frozen_string_literal: true

class AutoEndReservationMailer < ApplicationMailer

  def notify_auto_ended(reservation, _ended_by_user)
    @reservation = reservation
    @order_detail = reservation.order_detail
    @user = @reservation.user
    @facility = @order_detail.facility
    @product = @order_detail.product

    reply_to = @facility.email || Settings.email.from

    mail(
      to: @user.email,
      reply_to: reply_to,
      subject: text("notify_auto_ended.subject",
                    facility: @facility.abbreviation,
                    product: @product.name)
    )
  end

  protected

  def translation_scope
    "views.auto_end_reservation_mailer"
  end

end
