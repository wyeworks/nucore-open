# frozen_string_literal: true

class FacilityReservationsController < ApplicationController

  include SortableColumnController
  include NewInprocessController
  include ProblemOrderDetailsController
  include TabCountHelper

  helper TimelineHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource class: Reservation, except: [:send_problem_notifications, :notification_count]

  def initialize
    super
    @active_tab = "admin_reservations"
  end

  # GET /facilities/:facility_id/reservations
  # Provided by NewInprocessController
  # def index
  # end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id/edit
  def edit
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product

    raise ActiveRecord::RecordNotFound unless @reservation == Reservation.find(params[:id])
    set_windows

    redirect_to facility_order_order_detail_reservation_path(current_facility, @order, @order_detail, @reservation) if @reservation.locked?
  end

  # PUT /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id
  def update
    @order        = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product
    raise ActiveRecord::RecordNotFound if @reservation != Reservation.find(params[:id]) || @reservation.locked?
    set_windows

    @reservation.assign_times_from_params(reservation_params)

    additional_notice = ""

    # We're updating a reservation before it's been completed
    if reserve_changed?
      @order_detail.assign_estimated_price
      additional_notice = " Estimated cost has been updated as well."
    end

    Reservation.transaction do
      begin
        @reservation.save_as_user!(session_user)
        @order_detail.save!
        flash.now[:notice] = "The reservation has been updated successfully.#{additional_notice}"
      rescue StandardError
        flash.now[:error] = "An error was encountered while updating the reservation."
        raise ActiveRecord::Rollback
      end
    end

    render action: "edit"
  end

  # GET /facilities/:facility_id/orders/:order_id/order_details/:order_detail_id/reservations/:id
  def show
    @order        = Order.find(params[:order_id])
    @order_detail = OrderDetail.find(params[:order_detail_id])
    @reservation  = @order_detail.reservation
    @instrument   = @order_detail.product
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/reservations/new
  # for admin reservations
  def new
    @instrument   = current_facility.instruments.find_by!(url_name: params[:instrument_id])
    @reservation = @instrument.next_available_reservation ||
                   @instrument.admin_reservations.build(duration_mins: @instrument.min_reserve_mins)
    @reservation = @reservation.becomes(AdminReservation)
    @reservation.round_reservation_times
    @reservation_form = AdminReservationForm.new(@reservation)
    @reservation_form.repeat_end_date = @reservation.reserve_end_at

    render layout: "two_column"
  end

  # POST /facilities/:facility_id/instruments/:instrument_id/reservations
  # for admin reservations
  def create
    @instrument =
      current_facility.instruments.find_by!(url_name: params[:instrument_id])
    @reservation = @instrument.admin_reservations.new
    @reservation_form = AdminReservationForm.new(@reservation)
    @reservation_form.assign_attributes(admin_reservation_params.merge(created_by: current_user))
    @reservation_form.assign_times_from_params(admin_reservation_params)

    if @reservation_form.save
      flash[:notice] = "The reservation has been created successfully."
      redirect_to facility_instrument_schedule_url
    else
      render action: "new", layout: "two_column"
    end
  end

  # GET /facilities/:facility_id/instruments/:instrument_id/reservations/:id/edit_admin
  def edit_admin
    @instrument  = current_facility.instruments.find_by!(url_name: params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:reservation_id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?
    render layout: "two_column"
  end

  # PUT /facilities/:facility_id/instruments/:instrument_id/reservations/:id
  def update_admin
    @instrument  = current_facility.instruments.find_by!(url_name: params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:reservation_id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?

    @reservation.assign_times_from_params(admin_reservation_params)
    @reservation.assign_attributes(admin_reservation_params)

    if @reservation.save
      flash[:notice] = "The reservation has been updated successfully."
      redirect_to facility_instrument_schedule_url
    else
      render action: "edit_admin", layout: "two_column"
    end
  end

  # POST /facilities/:facility_id/reservations/batch_update
  def batch_update
    redirect_to facility_reservations_path

    msg_hash = batch_updater.update!

    # add flash messages if necessary
    flash.merge!(msg_hash) if msg_hash
  end

  # DELETE  /facilities/:facility_id/instruments/:instrument_id/reservations/:id
  def destroy
    @instrument  = current_facility.instruments.find_by!(url_name: params[:instrument_id])
    @reservation = @instrument.reservations.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @reservation.order_detail_id.nil?

    @reservation.destroy
    flash[:notice] = "The reservation has been removed successfully"
    redirect_to facility_instrument_schedule_url
  end

  def timeline
    @display_datetime = parse_usa_date(params[:date]) || Time.current.beginning_of_day

    @schedules = current_facility.schedules_for_timeline(:facility_instruments)
    instrument_ids = @schedules.flat_map { |schedule| schedule.facility_instruments.map(&:id) }
    @reservations_by_instrument = Reservation.for_timeline(@display_datetime, instrument_ids).group_by(&:product)
  end

  protected

  def reservation_params
    params.require(:reservation).permit(:reserve_start_date,
                                        :reserve_start_hour,
                                        :reserve_start_min,
                                        :reserve_start_meridian,
                                        :duration_mins,
                                        :reserve_start_at,
                                        :reserve_end_at)
  end

  def admin_reservation_params
    admin_params = params.require(:admin_reservation)
                         .except(:reserve_end_date,
                                 :reserve_end_hour,
                                 :reserve_end_min,
                                 :reserve_end_meridian,
                                 :expires)
                         .permit(:admin_note,
                                 :user_note,
                                 :expires_mins_before,
                                 :category,
                                 :repeats,
                                 :repeat_frequency,
                                 :repeat_end_date,
                                 :reserve_start_date,
                                 :reserve_start_hour,
                                 :reserve_start_min,
                                 :reserve_start_meridian,
                                 :duration_mins,
                                 :admin_note)
    admin_params[:expires_mins_before] = nil if params[:admin_reservation][:expires] == "0"
    admin_params[:repeat_frequency] = nil if params[:admin_reservation][:repeats] == "0"
    admin_params[:repeat_end_date] = nil if params[:admin_reservation][:repeats] == "0"
    admin_params
  end

  def show_problems_path
    show_problems_facility_reservations_path
  end

  private

  def batch_updater
    @batch_updater ||= OrderDetailBatchUpdater.new(params[:order_detail_ids], current_facility, session_user, params, "reservations")
  end

  def reserve_changed?
    @reservation.admin_editable? &&
      (@reservation.reserve_start_at_changed? || @reservation.reserve_end_at_changed?)
  end

  def problem_order_details
    current_facility
      .problem_reservation_order_details
      .joins(:reservation)
  end

  def new_or_in_process_orders
    current_facility.order_details.new_or_inprocess.reservations
                    .includes(:reservation)
  end

  def set_windows
    @max_window = 365
    @max_days_ago = -365
    # initialize calendar time constraints
    @min_date     = Time.zone.now.strftime("%Y%m%d")
    @max_date     = (Time.zone.now + @max_window.days).strftime("%Y%m%d")
  end

end
