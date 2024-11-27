# frozen_string_literal: true

module ReservationsHelper

  def add_accessories_link(reservation)
    if reservation.order_detail.accessories? && reservation.reserve_end_at < Time.zone.now
      link_to t("product_accessories.pick_accessories.link"), reservation_pick_accessories_path(reservation), class: "has_accessories persistent"
    end
  end

  def reservation_pick_accessories_path(reservation)
    new_order_order_detail_accessory_path(reservation.order_detail.order, reservation.order_detail)
  end

  def kiosk_reservation_pick_accessories_path(reservation, switch=nil)
    new_order_order_detail_kiosk_accessory_path(reservation.order_detail.order, reservation.order_detail, switch: switch)
  end

  def default_duration_mins
    duration = @instrument.min_reserve_mins
    duration = nil if duration == 0
    duration ||= 30 if @instrument.reserve_interval < 30
    duration ||= @instrument.reserve_interval
  end

  def end_reservation_class(reservation)
    reservation.order_detail.accessories? ? :has_accessories : nil
  end

  def reservation_actions(reservation, redirect_to_order_id: nil)
    delimiter = "&nbsp;|&nbsp;".html_safe
    links = ReservationUserActionPresenter.new(self, reservation).user_actions(redirect_to_order_id)
    safe_join(links, delimiter)
  end

  def kiosk_reservation_actions(reservation)
    delimiter = "&nbsp;|&nbsp;".html_safe
    links = ReservationUserActionPresenter.new(self, reservation).kiosk_user_actions
    safe_join(links, delimiter)
  end

  def kiosk_reservation_user(reservation)
    reservation.display_user&.full_name || text("no_user")
  end

  def reservation_view_edit_link(reservation)
    ReservationUserActionPresenter.new(self, reservation).view_edit_link
  end

  def start_time_editing_enabled?(reservation)
    !start_time_editing_disabled?(reservation)
  end

  def start_time_editing_disabled?(reservation)
    return false if !reservation.persisted? || reservation.in_cart?

    original = Reservation.find(reservation.id)
    !original.reserve_start_at_editable?
  end

  def end_time_editing_disabled?(reservation)
    return false if !reservation.persisted? || reservation.in_cart?

    original = Reservation.find(reservation.id)
    !original.reserve_end_at_editable?
  end

  def weekday_opening_times
    @weekday_opening_times ||= ScheduleRules::OpenHours.new(@instrument.schedule_rules).per_weekday
  end

  def reservations_calendar_config
    {
      show_tooltip: (@instrument.daily_booking? || @instrument.show_details).to_s,
      start_editable: (!@instrument.daily_booking? && start_time_editing_enabled?(@reservation)).to_s,
      default_view: @instrument.daily_booking? ? "month" : "agendaWeek",
    }
  end

end
