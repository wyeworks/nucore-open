# frozen_string_literal: true

module TimelineHelper

  def show_relay_controls?(instrument)
    @display_datetime.today? && instrument.has_real_relay?
  end

  def show_refresh_all_relays?(instruments)
    instruments.any? { |instrument| show_relay_controls?(instrument) }
  end

  def relay_toggle_options(instrument)
    options = { disabled: true }

    options[:data] = if can?(:switch, Instrument)
                       { relay_url: facility_instrument_switch_path(instrument.facility, instrument) }
                     else
                       { readonly: true }
                     end

    options
  end

  def reservation_classes(reservation, product = nil)
    classes = ["unit"]
    if reservation.product == product
      classes << "tip" unless reservation.blackout?
    else
      classes << "other-product"
    end

    classes << "blackout" if reservation.blackout?
    classes << "admin" if reservation.admin?
    classes << "behalf_of" if reservation.ordered_on_behalf_of?
    classes << "in_progress" if reservation.can_switch_instrument?
    classes << "status_#{display_status_class(reservation.order_detail)}" if reservation.order_detail
    classes.concat spans_midnight_class(reservation.reserve_start_at, reservation.reserve_end_at)
    classes.join(" ")
  end

  MINUTE_TO_PIXEL_RATIO = 0.6
  def datetime_left_position(display_date, datetime)
    # don't start before midnight of the display_date
    time_to_use = [datetime, display_date.beginning_of_day].max

    "#{((time_to_use - display_date.beginning_of_day) / 60 * MINUTE_TO_PIXEL_RATIO).floor}px"
  end

  def datetime_width(display_date, datetime_start, datetime_end)
    # cut off the beginning if it starts before midnight
    start_datetime_to_use = [datetime_start, display_date.beginning_of_day].max

    # cut it off at midnight of start day if end time goes into the next day
    end_datetime_to_use = [datetime_end, display_date.end_of_day].min
    # In Ruby 1.8.7, the subtraction leads to a .99999 value, so go ahead and round that off
    "#{((end_datetime_to_use - start_datetime_to_use).round(4) / 60 * MINUTE_TO_PIXEL_RATIO).floor}px"
  end

  def reservation_width(display_date, reservation)
    datetime_width(display_date, reservation.display_start_at, reservation.display_end_at)
  end

  def reservation_left_position(display_date, reservation)
    datetime_left_position(display_date, reservation.display_start_at)
  end

  def spans_midnight_class(datetime_start, datetime_end)
    classes = []
    classes << "runs_into_tomorrow" if datetime_end > @display_datetime.end_of_day
    classes << "runs_into_yesterday" if datetime_start < @display_datetime.beginning_of_day
    classes
  end

  def reservation_user_display(reservation)
    if reservation.offline?
      t(".offline_reservation")
    elsif reservation.admin?
      t(".admin_reservation")
    else
      reservation.user
    end
  end

  def reservation_date_range_display(date, reservation)
    # start = date.beginning_of_day >= reservation.display_start_at ?
    "#{reservation_date_in_day(date, reservation.display_start_at)} &ndash; #{reservation_date_in_day(date, reservation.display_end_at)}".html_safe
  end

  def reservation_date_in_day(day_date, reservation_date)
    if day_date.beginning_of_day < reservation_date && reservation_date < day_date.end_of_day
      human_time(reservation_date)
    else
      format_usa_datetime(reservation_date)
    end
  end

  def display_status_class(order_detail)
    order_detail.canceled_at ? "canceled" : order_detail.order_status.to_s.downcase
  end

end
