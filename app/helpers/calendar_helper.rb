# frozen_string_literal: true

module CalendarHelper

  def product_calendar_view(product)
    return "month" if product.daily_booking?

    "agendaWeek"
  end

  def calendar_events_path(facility, product, **params)
    opts = {
      format: "js",
      with_details: product.show_details?,
    }
    opts[:view] = product_calendar_view(product)
    opts.merge!(params)

    facility_instrument_reservations_path(
      facility,
      product,
      opts
    )
  end

end
