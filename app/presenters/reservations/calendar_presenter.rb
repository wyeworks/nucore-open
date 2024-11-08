# frozen_string_literal: true

module Reservations

  class CalendarPresenter < DelegateClass(Reservation)

    def as_calendar_object(options = {})
      calendar_object_default.merge(reservation_options(options))
    end

    private

    def reservation_options(options)
      if order.present?
        if options[:with_details].present?
          {
            title: order.user.full_name,
            email: order.user.email,
            orderId: order.id,
            orderNote: order_detail.facility.show_order_note? ? order_detail.note : nil,
          }
        else
          {}
        end
      elsif offline?
        {
          title: "Instrument Offline",
          email: created_by.try(:full_name),
        }
      else
        hash = {
          title: model_name.human,
          email: created_by.try(:full_name),
        }
        hash[:expiration] = "Expires #{MinutesToTimeFormatter.new(expires_mins_before)} prior" if expires_mins_before.present?
        hash[:userNote] = user_note
        hash
      end
    end

    def calendar_object_default
      {
        start: display_start_at.iso8601,
        end: display_end_at.iso8601,
        allDay: false,
        title: model_name.human,
        product: product.name,
        id:,
      }
    end

  end

end
