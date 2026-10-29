# frozen_string_literal: true

module OfflineReservationArguments
  extend ActiveSupport::Concern

  included do
    helper_method :offline_notification_arguments
  end

  def offline_notification_arguments
    {
      facility_contact: facility_contact_text(reservation.facility.email),
      facility_name: reservation.facility.name,
      facility_url: facility_url(reservation.facility),
      product: reservation.product,
      reservation_time: I18n.l(reservation.reserve_start_at, format: :timeonly),
      order_detail_url: order_order_detail_url(reservation.order, reservation.order_detail),
    }
  end

  private

  def facility_contact_text(email)
    if email.present?
      text("views.offline_cancellation_mailer.send_notification.facility_contact", email:)
    else
      ""
    end
  end
end
