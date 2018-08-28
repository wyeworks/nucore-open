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

  def default_duration
    duration = @instrument.min_reserve_mins
    duration = nil if duration == 0
    duration ||= 30 if @instrument.reserve_interval < 30
    duration ||= @instrument.reserve_interval
  end

  def end_reservation_class(reservation)
    reservation.order_detail.accessories? ? :has_accessories : nil
  end

  def reservation_actions(reservation)
    delimiter = "&nbsp;|&nbsp;".html_safe
    links = ReservationUserActionPresenter.new(self, reservation).user_actions
    safe_join(links, delimiter)
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

end
