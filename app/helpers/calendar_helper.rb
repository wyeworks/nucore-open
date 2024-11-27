# frozen_string_literal: true

module CalendarHelper

  def product_calendar_view(product)
    if product.daily_booking?
      "month"
    else
      "agendaWeek"
    end
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
