class OfflineReservationsController < ApplicationController

  admin_tab :all
  layout "two_column"

  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :load_instrument
  before_action :load_reservation, only: %i(edit update)

  load_and_authorize_resource

  def new
    @reservation = @instrument.offline_reservations.new
  end

  def create
    @reservation = @instrument.offline_reservations.new(create_params)
    @reservation.assign_attributes(created_by: current_user)

    if @reservation.save
      flag_ongoing_reservations_as_problem
      flash[:notice] = text("create.success")
      redirect_to facility_instrument_schedule_path
    else
      render action: "new"
    end
  end

  def bring_online
    @instrument.online!
    if @instrument.online?
      flash[:notice] = text("bring_online.success")
    else
      flash[:error] = text("bring_online.error")
    end

    redirect_to facility_instrument_schedule_path
  end

  def edit
  end

  def update
    if @reservation.update(update_params)
      flash[:notice] = text("update.success")
      redirect_to facility_instrument_schedule_path
    else
      flash[:error] = text("update.error")
      render action: "edit"
    end
  end

  private

  def flag_ongoing_reservations_as_problem
    OrderDetail
      .where(id: @instrument.reservations.ongoing.pluck(:order_detail_id))
      .each(&:force_complete!)
  end

  def load_instrument
    @instrument = current_facility.instruments.find_by!(url_name: params[:instrument_id])
  end

  def load_reservation
    @reservation = @instrument.offline_reservations.find(params[:id])
  end

  def create_params
    params.require(:offline_reservation)
          .permit(:admin_note, :category)
          .merge(reserve_start_at: Time.current)
  end

  def update_params
    params.require(:offline_reservation).permit(:admin_note, :category)
  end

end
