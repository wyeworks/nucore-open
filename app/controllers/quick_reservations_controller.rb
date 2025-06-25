# frozen_string_literal: true

class QuickReservationsController < ApplicationController
  layout "quick_reservation"

  before_action :authenticate_user!
  load_resource :facility, find_by: :url_name
  load_resource :instrument, through: :facility, find_by: :url_name
  before_action :set_actionable_reservation, only: [:start, :new]
  before_action :prepare_reservation_data, only: [:new, :create]

  # GET /facilities/:facility_id/instruments/:instrument_id/quick_reservations/:id
  def show
    @reservation = current_user.reservations.find params[:id]
    raise ActiveRecord::RecordNotFound unless @reservation
    redirect_to new_facility_instrument_quick_reservation_path(@facility, @instrument) if @reservation.actual_end_at
    @order = @reservation.order
    @order_detail = @order.order_details.first
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/quick_reservations/new
  def new
    redirect_to facility_instrument_quick_reservation_path(@facility, @instrument, @reservation) if @reservation

    # Set up records to authorize against, these are not used in the view
    build_order
    @reservation = NextAvailableReservationFinder.new(@instrument).next_available_for(current_user, current_user)
    @reservation.order_detail = @order_detail
    authorize! :new, @reservation

    interval = @instrument.quick_reservation_intervals.first
    @walkup_available = @instrument.walkup_available?(interval:)
  end

  # POST /facilities/:facility_id/instruments/:instrument_id/quick_reservations
  def create
    # Create reservation data here to ensure a valid start time.
    # If a user sits on the #new page for a little bit of time, the start time shown
    # on that page will no longer be valid - for example,
    # if that start time is in the past when the user submits the form.
    params[:reservation][:reserve_start_date] = @reservation_data[:reserve_start_at].to_s
    params[:reservation][:reserve_start_hour] = @reservation_data[:reserve_start_at].hour
    params[:reservation][:reserve_start_min] = @reservation_data[:reserve_start_at].min
    params[:reservation][:reserve_start_meridian] = @reservation_data[:reserve_start_at].strftime("%p")

    build_order
    creator = ReservationCreator.new(@order, @order_detail, params)
    @reservation = creator.reservation

    if creator.save(current_user)
      # Check if the user can create a reservation
      facility_ability = Ability.new(session_user, @order.facility, self)
      @order.being_purchased_by_admin = facility_ability.can?(:act_as, @order.facility)
      authorize! :create, @reservation

      @order.transaction do
        order_purchaser.purchase!
      end

      if order_purchaser.success?
        if @reservation.can_switch_instrument_on?
          @reservation.start_reservation!
        end

        if @reservation.started?
          flash[:notice] = "Reservation started"
        else
          # failed to start
          flash[:error] = @reservation.errors.full_messages.join("<br>").html_safe
        end
      else
        # failed to purchase order
        flash[:error] = order_purchaser.errors.join("<br>").html_safe
      end
      redirect_to facility_instrument_quick_reservation_path(
        @facility,
        @instrument,
        @reservation
      )
    else
      # failed to save reservation
      flash[:error] = creator.error.html_safe
      render(:new)
    end
  end

  # POST /facilities/:facility_id/instruments/:instrument_id/quick_reservations/start
  def start
    if @reservation&.movable_to_now? && @reservation&.move_to_earliest
      @reservation&.start_reservation!
    end

    if @reservation&.started?
      flash[:notice] = "Reservation started"
      redirect_to facility_instrument_quick_reservation_path(@facility, @instrument, @reservation)
    else
      # failed to start
      flash[:error] = @startable.errors.full_messages.join("<br>").html_safe

      redirect_to facility_instrument_quick_reservation_path(
        @facility,
        @instrument,
        @startable.reservation
      )
    end
  end

  private

  def ability_resource
    @reservation
  end

  def reservation_params
    params.permit(:reservation, :order_account)
  end

  def prepare_reservation_data
    @possible_reservation_data = @instrument.quick_reservation_data

    # Check if the user can create a reservation, among other things, this will
    # catch instruments with no schedule rules
    instrument_for_cart = InstrumentForCart.new(@instrument, quick_reservation: true)
    @can_add_to_cart = instrument_for_cart.purchasable_by?(current_user, current_user)

    if instrument_for_cart.error_message
      flash.now[:notice] = instrument_for_cart.error_message
    else
      # if no reservations are available right now, find reservations at the next
      # available time
      if @possible_reservation_data.empty?
        duration = @instrument.quick_reservation_intervals.first.minutes
        next_available_reservation = @instrument.next_available_reservation(duration:)
        after = next_available_reservation.reserve_start_at
        @possible_reservation_data = @instrument.quick_reservation_data(after:)
      end

      @reservation_data = @possible_reservation_data.first

    end
  end

  def set_actionable_reservation
    reservations = current_user.reservations.where(product_id: @instrument.id).joins(:order_detail).merge(OrderDetail.new_or_inprocess)
    startable = reservations.find(&:movable_to_now?)
    ongoing = reservations.ongoing.first

    @reservation = ongoing || startable
  end

  def build_order
    @order = Order.new(
      user: current_user,
      facility: current_facility,
      created_by: current_user.id,
    )
    @order_detail = @order.order_details.build(
      product: @instrument,
      quantity: 1,
      created_by: current_user.id,
    )
  end

  def order_purchaser
    @order_purchaser ||= OrderPurchaser.new(
      acting_as: false,
      order: @order,
      order_in_past: false,
      params:,
      user: current_user,
    )
  end
end
