# frozen_string_literal: true

# Mostly copied over from ReservationsController, making some
# changes as needed to fit the use case of the Kiosk View page.
# The Kiosk View page provides easy access to commonly used
# reservation actions, saving some clicks for the user.
# The user should be prompted to login before action is taken,
# then logged out and redirected back to the Kiosk View.
class KioskReservationsController < ApplicationController

  before_action :check_kiosk_enabled, only: :index
  before_action :check_acting_as, only: [:switch_instrument]
  before_action :load_and_check_resources, except: [:index]

  include ReservationSwitch

  def index
    @display_datetime = Time.current.beginning_of_day
    sign_out if params[:sign_out].present?
    @schedules = current_facility.schedules_for_timeline(:public_instruments)
    instrument_ids = @schedules.flat_map { |schedule| schedule.public_instruments.map(&:id) }
    todays_reservations = Reservation.for_timeline(Time.current.beginning_of_day, instrument_ids)
    @actionable_reservations = todays_reservations.select(&:kiosk?)

    @reservations_by_instrument = todays_reservations.group_by(&:product)

    if params[:refresh]
      render partial: "reservations_table", locals: { reservations: @actionable_reservations }
    end
  end

  def begin
    @switch = "on"
    render layout: false
  end

  def stop
    @switch = "off"
    render layout: false
  end

  # GET /orders/:order_id/order_details/:order_detail_id/kiosk_reservations/switch_instrument
  def switch_instrument
    respond_error(text("authentication.error")) && return unless can_switch?
    respond_error(text("switch.error")) && return unless switch_value_present?

    switch_instrument!(params[:switch])
    head :ok
  end

  private

  def can_switch?
    password = params.dig(:kiosk_reservations, :password)
    kiosk_user = Users::AuthChecker.new(@reservation.user, password)
    kiosk_user.authenticated? && kiosk_user.authorized?(:start_stop, @reservation)
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
      redirect_to action: :index
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

  def respond_error(message)
    @switch = params[:switch]
    flash[:error] = message
    template = if @switch == "off"
                 :stop
               elsif @switch == "on"
                 :begin
               else
                 :error
               end
    render template, status: 406, layout: false
  end

  def check_kiosk_enabled
    return if current_facility&.kiosk_enabled? && SettingsHelper.feature_on?(:kiosk_view)

    if current_user
      render "errors/forbidden", status: :forbidden
    else
      redirect_to new_user_session_path, alert: "You need to login to access this page." and return
    end
  end

end
