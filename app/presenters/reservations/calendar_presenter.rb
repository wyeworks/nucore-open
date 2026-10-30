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
    def as_calendar_object(options = {})
      super.merge(
        title: "Instrument Offline",
        className: "unavailable",
      ).tap do |hash|
        hash[:email] = created_by.try(:full_name) if options[:with_details].present?
      end
    end
  end

  class OrderCalendarPresenter < CalendarPresenter
    def as_calendar_object(options = {})
      ret = super

      class_names = []
      class_names << "other-instrument" if options[:discriminate] && options[:instrument_id].present? && product_id != options[:instrument_id]
      class_names << "canceled" if canceled?
      ret[:className] = class_names if class_names.any?

      if options[:with_details].blank?
        ret[:title] = order.user.full_name if options[:user].present? && order.user == options[:user]
        return ret
      end

      ret.merge(
        title: order.user.full_name,
        email: order.user.email,
        orderId: order.id,
        orderNote: order_detail.facility.show_order_note? ? order_detail.note : nil,
      )
    end
  end

  class FallbackCalendarPresenter < CalendarPresenter
    def as_calendar_object(options = {})
      super.merge(
        title: model_name.human,
        userNote: user_note,
      ).tap do |hash|
        hash[:email] = created_by.try(:full_name) if options[:with_details].present?

        hash[:expiration] = "Expires #{MinutesToTimeFormatter.new(expires_mins_before)} prior" if expires_mins_before.present?

        hash[:className] = "unavailable" if __getobj__.is_a?(AdminReservation)
      end
    end
  end
end
