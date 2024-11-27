# frozen_string_literal: true

module Reservations

  class CalendarPresenter < DelegateClass(Reservation)
    def as_calendar_object(_options = {})
      {
        start: display_start_at.iso8601,
        end: display_end_at.iso8601,
        allDay: false,
        title: model_name.human,
        product: product.name,
        id:,
      }
    end

    def self.build(reservation)
      if reservation.order.present?
        OrderCalendarPresenter.new(reservation)
      elsif reservation.offline?
        OfflineCalendarPresenter.new(reservation)
      else
        FallbackCalendarPresenter.new(reservation)
      end
    end
  end

  class OfflineCalendarPresenter < CalendarPresenter
    def as_calendar_object(_options = {})
      super.merge(
        title: "Instrument Offline",
        email: created_by.try(:full_name),
        className: "unavailable"
      )
    end
  end

  class OrderCalendarPresenter < CalendarPresenter
    def as_calendar_object(options = {})
      ret = super

      return ret if options[:with_details].blank?

      ret.merge(
        title: order.user.full_name,
        email: order.user.email,
        orderId: order.id,
        orderNote: order_detail.facility.show_order_note? ? order_detail.note : nil,
      )
    end
  end

  class FallbackCalendarPresenter < CalendarPresenter
    def as_calendar_object(_options = {})
      super.merge(
        title: model_name.human,
        email: created_by.try(:full_name),
        userNote: user_note,
      ).tap do |hash|
        if expires_mins_before.present?
          hash[:expiration] = "Expires #{MinutesToTimeFormatter.new(expires_mins_before)} prior"
        end
        hash[:className] = "unavailable" if __getobj__.is_a?(AdminReservation)
      end
    end
  end
end
