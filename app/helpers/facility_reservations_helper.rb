# frozen_string_literal: true

module FacilityReservationsHelper

  def offline_category_collection
    I18n.t("offline_reservations.categories").invert.to_a
  end

  def admin_category_collection
    I18n.t("admin_reservations.categories").invert.to_a
  end

  def reservation_category_label(reservation)
    I18n.t(reservation.category.presence, scope: "#{reservation.class.name.underscore}s.categories", default: "")
  end

  def reservation_links(reservation)
    return if reservation.offline?

    links = []
    if reservation.admin?
      links << link_to(I18n.t("reservations.edit.link"), edit_admin_reservation_path(reservation))
      links << link_to(
        I18n.t("reservations.delete.link"),
        facility_instrument_reservation_path(reservation.facility, reservation.product, reservation),
        data: { confirm: I18n.t("reservations.delete.confirm") },
        method: :delete,
      )
    else
      links << link_to(I18n.t("reservations.switch.start"), order_order_detail_reservation_switch_instrument_path(reservation.order, reservation.order_detail, reservation, switch: "on")) if reservation.can_switch_instrument_on?
      links << end_reservation_link(reservation)
      links << link_to(I18n.t("reservations.edit.link"), facility_order_path(reservation.facility, reservation.order))
    end
    links.join(" | ").html_safe
  end

  def end_reservation_link(reservation, html_classes = "")
    link_to(I18n.t("reservations.switch.end"), order_order_detail_reservation_switch_instrument_path(reservation.order, reservation.order_detail, reservation, switch: "off"), class: "#{end_reservation_class(reservation)} #{html_classes}") if reservation.can_switch_instrument_off?
  end

  def edit_admin_reservation_path(reservation)
    facility_instrument_reservation_edit_admin_path(reservation.facility,
                                                    reservation.product,
                                                    reservation)
  end

end
