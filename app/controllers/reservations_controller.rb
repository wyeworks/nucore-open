# frozen_string_literal: true

class ReservationsController < ApplicationController

  customer_tab  :all
  before_action :authenticate_user!, except: [:index]
  before_action :check_acting_as, only: [:switch_instrument, :list]
  before_action :load_basic_resources, only: [:new, :create, :edit, :update]
  before_action :load_and_check_resources, only: [:move, :switch_instrument]
  authorize_resource only: [:edit, :update, :move]

  include TranslationHelper
  include FacilityReservationsHelper
  helper TimelineHelper

  def initialize
    super
    @active_tab = "reservations"
  end

  def public_timeline
    @display_datetime = parse_usa_date(params[:date]) || Time.current.beginning_of_day

    @schedules = current_facility.schedules_for_timeline(:public_instruments)
    instrument_ids = @schedules.flat_map { |schedule| schedule.public_instruments.map(&:id) }
    @reservations_by_instrument = Reservation.for_timeline(@display_datetime, instrument_ids).group_by(&:product)
  end

  # GET /facilities/1/instruments/1/reservations.js?_=1279579838269&start=1279429200&end=1280034000
  def index
    @facility = Facility.find_by!(url_name: params[:facility_id])
    @instrument = @facility.instruments.find_by!(url_name: params[:instrument_id])

    @start_at = parse_time_param(params[:start]) || Time.zone.now
    @end_at = parse_time_param(params[:end]) || @start_at.end_of_day

    admin_reservations = @instrument.schedule.admin_reservations.in_range(@start_at, @end_at)
    user_reservations = @instrument.schedule
                                   .reservations
                                   .active
                                   .in_range(@start_at, @end_at)
                                   .includes(order_detail: { order: :user })
    offline_reservations = @instrument.offline_reservations.in_range(@start_at, @end_at)

    @reservations = admin_reservations + user_reservations + offline_reservations

    # We don't need the unavailable hours month view
    unless month_view?
      @rules = @instrument.schedule_rules

      if @instrument.requires_approval? && acting_user && acting_user.cannot_override_restrictions?(@instrument)
        @rules = @rules.available_to_user(acting_user)
      end

      @unavailable = ScheduleRule.unavailable(@rules)
    end

    @show_details = params[:with_details] == "true" && (@instrument.show_details? || can?(:administer, Reservation))

    respond_to do |format|
      as_calendar_object_options = { start_date: @start_at.beginning_of_day, with_details: @show_details }
      format.js do
        render json: Reservation.as_calendar_objects(@reservations, as_calendar_object_options) +
                     ScheduleRule.as_calendar_objects(@unavailable, as_calendar_object_options)
      end
    end
  end

  # GET /reservations
  # All My Resesrvations
  def list
    notices = []

    relation = acting_user.order_details
    in_progress = relation.with_in_progress_reservation
    @status = params[:status]
    @available_statuses = [in_progress.blank? ? "upcoming" : "upcoming_and_in_progress", "all"]

    if @status == "all"
      @order_details = relation.with_reservation
    elsif @status == "upcoming"
      @status = @available_statuses.first
      @order_details = in_progress + relation.with_upcoming_reservation
    else
      return redirect_to reservations_status_path(status: "upcoming")
    end

    @order_details = @order_details.paginate(page: params[:page])

    notices = @order_details.collect do |od|
      notice_for_reservation od.reservation
    end
    notices.compact!
    existing_notices = flash[:notice].presence ? [flash[:notice]] : []
    flash.now[:notice] = existing_notices.concat(notices).join("<br />").html_safe unless notices.empty?
  end

  # POST /orders/:order_id/order_details/:order_detail_id/reservations
  def create
    raise ActiveRecord::RecordNotFound unless @reservation.nil?

    creator = ReservationCreator.new(@order, @order_detail, params)
    if creator.save(session_user)
      @reservation = creator.reservation
      authorize! :create, @reservation
      flash[:notice] = I18n.t "controllers.reservations.create.success"
      flash[:error] = I18n.t("controllers.reservations.create.admin_hold_warning") if creator.reservation.conflicting_admin_reservation?

      if creator.merged_order?
        redirect_to facility_order_path(@order_detail.facility, @order_detail.order.merge_order || @order_detail.order)
      elsif creator.instrument_only_order?
        redirect_params = {}
        redirect_params[:send_notification] = "1" if params[:send_notification] == "1"
        # only trigger purchase if instrument
        # and is only thing in cart (isn't bundled or on a multi-add order)
        redirect_to purchase_order_path(@order, redirect_params)
      else
        redirect_to cart_path
      end
    else
      @reservation = creator.reservation
      flash.now[:error] = creator.error.html_safe
      set_windows
      render :new
    end
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/new
  def new
    raise ActiveRecord::RecordNotFound unless @reservation.nil?

    @reservation = NextAvailableReservationFinder.new(@instrument).next_available_for(current_user, acting_user)
    @reservation.order_detail = @order_detail

    authorize! :new, @reservation

    unless @instrument.can_be_used_by?(@order_detail.user)
      flash[:notice] = text(".acting_as_not_on_approval_list")
    end
    set_windows
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:id(.:format)
  def show
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = Reservation.find(params[:id])
    authorize! :show, @reservation

    raise ActiveRecord::RecordNotFound if @reservation != @order_detail.reservation

    respond_to do |format|
      format.html

      format.ics do
        calendar = ReservationCalendar.new(@reservation)
        send_data(calendar.to_ical,
                  type: "text/calendar", disposition: "attachment",
                  filename: calendar.filename)
      end
    end
  end

  # GET /orders/1/order_details/1/reservations/1/edit
  def edit
    redirect_to [@order, @order_detail, @reservation] if invalid_for_update?
    set_windows
  end

  # PUT  /orders/1/order_details/1/reservations/1
  def update
    if invalid_for_update?
      redirect_to [@order, @order_detail, @reservation], notice: I18n.t("controllers.reservations.update.failure")
      return
    end

    @reservation.assign_times_from_params(reservation_params)
    with_dropped_params do
      reservation_update_attributes = params.require(:reservation).permit(:note)
      @reservation.assign_attributes(reservation_update_attributes)
    end

    render_edit && return unless changes_valid_for_update?

    Reservation.transaction do
      begin
        # merge state can change after call to #save! due to OrderDetailObserver#before_save
        mergeable = @order_detail.order.to_be_merged?

        save_reservation_and_order_detail

        flash[:notice] = "The reservation was successfully updated."
        if mergeable
          redirect_to facility_order_path(@order_detail.facility, @order_detail.order.merge_order || @order_detail.order)
        else
          redirect_to (@order.purchased? ? reservations_path : cart_path)
        end
        return
      rescue ActiveRecord::RecordInvalid => e
        raise ActiveRecord::Rollback
      end
    end
    render_edit
  end

  # POST /orders/:order_id/order_details/:order_detail_id/reservations/:reservation_id/move
  def move
    if @reservation.move_to_earliest
      flash[:notice] = "The reservation was moved successfully."
    else
      flash[:error] = @reservation.errors.full_messages.join("<br/>").html_safe
    end

    redirect_to reservations_status_path(status: "upcoming")
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/:reservation_id/move
  def earliest_move_possible
    @reservation       = Reservation.find(params[:reservation_id])
    @earliest_possible = @reservation.earliest_possible

    if @earliest_possible
      @formatted_dates = {
        start_date: human_date(@earliest_possible.reserve_start_at),
        start_time: human_time(@earliest_possible.reserve_start_at),
        end_date: human_date(@earliest_possible.reserve_end_at),
        end_time: human_time(@earliest_possible.reserve_end_at),
      }
    end

    render layout: false
  end

  # GET /orders/:order_id/order_details/:order_detail_id/reservations/switch_instrument
  def switch_instrument
    authorize! :start_stop, @reservation

    raise ActiveRecord::RecordNotFound unless params[:switch] && (params[:switch] == "on" || params[:switch] == "off")

    begin
      case
      when params[:switch] == "on"
        switch_instrument_on!
      when params[:switch] == "off"
        switch_instrument_off!
      end
    rescue AASM::InvalidTransition => e
      flash[:error] = if e.failures.include?(:time_data_completeable?)
                        text("switch_instrument.prior_is_still_running")
                      else
                        e.message
                      end
    rescue => e
      flash[:error] = e.message
    end

    if params[:switch] == "off" && @order_detail.accessories?
      redirect_to new_order_order_detail_accessory_path(@order, @order_detail)
      return
    end

    redirect_to params[:redirect_to] || request.referer || order_order_detail_path(@order, @order_detail)
  end

  private

  def reservation_params
    reservation_params = params.require(:reservation)
                               .except(:reserve_end_date, :reserve_end_hour, :reserve_end_min, :reserve_end_meridian)
                               .permit(:reserve_start_date,
                                       :reserve_start_hour,
                                       :reserve_start_min,
                                       :reserve_start_meridian,
                                       :duration_mins,
                                       :note)

    # Prevent overriding of start time params after purchase if start time is locked,
    # e.g. you are in the lock window or the reservation has already started and
    # you are only allowed to extend the reservation.
    reservation_params.merge!(reservation_start_as_params) if fixed_start_time? && !@reservation.in_cart?

    reservation_params
  end

  def fixed_start_time?
    !@reservation.admin_editable? || !@reservation.reserve_start_at_editable?
  end

  def reservation_start_as_params
    {
      reserve_start_date: @reservation.reserve_start_date,
      reserve_start_hour: @reservation.reserve_start_hour,
      reserve_start_min: @reservation.reserve_start_min,
      reserve_start_meridian: @reservation.reserve_start_meridian,
    }
  end

  def switch_instrument_off!
    unless @reservation.other_reservation_using_relay?
      ReservationInstrumentSwitcher.new(@reservation).switch_off!
      flash[:notice] = "The instrument has been deactivated successfully"
    end
    session[:reservation_auto_logout] = true if params[:reservation_ended].present?
  end

  def switch_instrument_on!
    ReservationInstrumentSwitcher.new(@reservation).switch_on!
    flash[:notice] = "The instrument has been activated successfully"
    session[:reservation_auto_logout] = true if params[:reservation_started].present?
  end

  def load_basic_resources
    @order = Order.find(params[:order_id])
    # It's important that the order_detail be the same object as the one in @order.order_details.first
    @order_detail = @order.order_details.find { |od| od.id.to_i == params[:order_detail_id].to_i }
    raise ActiveRecord::RecordNotFound if @order_detail.blank?
    @reservation = @order_detail.reservation
    @instrument = @order_detail.product
    @facility = @instrument.facility
  rescue ActiveRecord::RecordNotFound
    flash[:error] = text("order_detail_removed")
    if @order
      redirect_to facility_path(@order.facility)
    else
      raise
    end
  end

  def load_and_check_resources
    load_basic_resources
    raise ActiveRecord::RecordNotFound if @reservation.blank?
  end

  def ability_resource
    if action_name == "index"
      current_facility
    else
      @reservation
    end
  end

  # TODO: you shouldn't be able to edit reservations that have passed or are outside of the cancellation period (check to make sure order has been placed)
  def invalid_for_update?
    params[:id].to_i != @reservation.id ||
      @reservation.actual_end_at ||
      !editable_by_current_user?
  end

  def editable_by_current_user?
    if current_ability.can?(:manage, @reservation) && @reservation.admin_editable?
      true
    elsif @reservation.can_customer_edit?
      true
    else
      false
    end
  end

  def save_reservation_and_order_detail
    @reservation.save_as_user!(session_user)
    @order_detail.assign_estimated_price(@reservation.reserve_end_at)
    @order_detail.save_as_user!(session_user)
  end

  def set_windows
    @reservation_window = ReservationWindow.new(@reservation, current_user)
  end

  def notice_for_reservation(reservation)
    return unless reservation

    if reservation.can_switch_instrument_off? # do you need to click stop
      I18n.t("reservations.notices.can_switch_off", reservation: reservation)
    elsif reservation.can_switch_instrument_on? # do you need to begin your reservation
      I18n.t("reservations.notices.can_switch_on", reservation: reservation)
    elsif reservation.canceled?
    # no message
    # do you have a reservation for today that hasn't ended
    elsif upcoming_today? reservation
      I18n.t("reservations.notices.upcoming", reservation: reservation)
    end
  end

  def upcoming_today?(reservation)
    now = Time.zone.now
    (reservation.reserve_start_at.to_date == now.to_date || reservation.reserve_start_at < now) && reservation.reserve_end_at > now
  end

  # Some browsers are not updating their cached JS and have an out-of-date calendar
  # JS library which uses unix timestamps for the parameters. This allows us to handle both.
  def parse_time_param(string_value)
    return unless string_value
    Time.zone.parse(string_value)
  rescue ArgumentError
    Time.zone.at(string_value.to_i)
  end

  def helpers
    ActionController::Base.helpers
  end

  # `1.week` causes a problem with daylight saving week since it's technically longer
  # than a week
  def month_view?
    @end_at - @start_at > 8.days
  end

  def render_edit
    set_windows
    render action: "edit"
  end

  def changes_valid_for_update?
    duration_change_valid? && NotePresenceValidator.new(@reservation).valid?
  end

  def duration_change_valid?
    validator = Reservations::DurationChangeValidations.new(@reservation)
    validator.valid?
  end

end
