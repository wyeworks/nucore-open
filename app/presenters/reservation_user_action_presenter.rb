# frozen_string_literal: true

class ReservationUserActionPresenter

  attr_accessor :reservation, :controller
  delegate :order_detail, :order, :facility, :product,
           :can_switch_instrument?, :can_switch_instrument_on?, :can_switch_instrument_off?,
           :can_cancel?, :startable_now?, :can_customer_edit?, :started?, :ongoing?, to: :reservation

  delegate :current_facility, to: :controller

  delegate :link_to, to: "ActionController::Base.helpers"
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper
  include ReservationsHelper

  def initialize(controller, reservation)
    @reservation = reservation
    @controller = controller
  end

  def user_actions
    actions = []
    actions << accessories_link if accessories?

    if can_switch_instrument?
      actions << switch_actions
    elsif startable_now?
      actions << move_link
    end

    actions << report_an_issue_link

    actions << cancel_link if can_cancel?

    actions << fix_problem_link if can_fix_problem?

    actions.compact
  end

  def view_edit_link
    link_to reservation, view_edit_path
  end

  def cancel_link(path = cancel_order_order_detail_path(order, order_detail))
    confirm_key = if canceler.total_cost > 0
                    canceler.charge_full_price? ? "confirm_with_full_price" : "confirm_with_fee"
                  else
                    "confirm"
                  end
    confirm_text = I18n.t(confirm_key, scope: "reservations.delete", fee: number_to_currency(canceler.total_cost))
    link_to I18n.t("reservations.delete.link"), path, method: :put, data: { confirm: confirm_text }
  end

  def canceler
    @canceler ||= CancellationFeeCalculator.new(order_detail)
  end

  private

  def accessories?
    ongoing? && order_detail.accessories?
  end

  def accessories_link
    link_to I18n.t("product_accessories.pick_accessories.title"), reservation_pick_accessories_path(reservation), class: "has_accessories persistent"
  end

  def view_edit_path
    if can_customer_edit?
      edit_order_order_detail_reservation_path(order, order_detail, reservation)
    else
      order_order_detail_reservation_path(order, order_detail, reservation)
    end
  end

  def switch_actions
    if can_switch_instrument_on?
      link_to I18n.t("reservations.switch.start"),
              order_order_detail_reservation_switch_instrument_path(
                order, order_detail, reservation,
                switch: "on", reservation_started: "on")
    elsif can_switch_instrument_off?
      link_to I18n.t("reservations.switch.end"),
              order_order_detail_reservation_switch_instrument_path(
                order, order_detail, reservation,
                switch: "off", reservation_ended: "on"),
              class: end_reservation_class(reservation),
              data: { refresh_on_cancel: true }
    end
  end

  def move_link
    link_to I18n.t("reservations.moving_up.link"), order_order_detail_reservation_move_reservation_path(order, order_detail, reservation),
            class: "move-res",
            data: { reservation_id: reservation.id }
  end

  def report_an_issue_link
    link_to(I18n.t("views.instrument_issues.new.title"), new_facility_instrument_issue_path(facility, product))
  end

  def fix_problem_link
    link_to(I18n.t("views.reservations.my_table.fix_reservation"), edit_problem_reservation_path(reservation))
  end

  def can_fix_problem?
    OrderDetails::ProblemResolutionPolicy.new(order_detail).user_can_resolve?
  end

end
