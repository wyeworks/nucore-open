# frozen_string_literal: true

class ProblemReservationsController < ApplicationController

  customer_tab :all

  before_action :authenticate_user!
  before_action :load_and_authorize_reservation
  before_action :prevent_double_update, only: :update
  before_action { @active_tab = "reservations" }

  def edit
    render :resolved if !editable? && resolved?
  end

  def update
    @order_detail.assign_attributes(
      problem_description_key_was: @order_detail.problem_description_key,
      problem_resolved_at: Time.current,
      problem_resolved_by: current_user,
    )
    @reservation.assign_times_from_params(update_params)

    if @reservation.save
      if @order_detail.accessories?
        redirect_to new_order_order_detail_accessory_path(@order_detail.order, @order_detail), notice: text("update.success")
      else
        redirect_to reservations_status_path(status: "all"), notice: text("update.success")
      end
    else
      render :edit
    end
  end

  private

  def prevent_double_update
    redirect_to order_order_detail_path(@order_detail.order, @order_detail) unless editable?
  end

  def update_params
    params.require(:reservation).permit(
      :actual_end_date, :actual_end_hour, :actual_end_min, :actual_end_meridian, :actual_duration_mins
    )
  end

  def editable?
    OrderDetails::ProblemResolutionPolicy.new(@order_detail).user_can_resolve?
  end

  def resolved?
    OrderDetails::ProblemResolutionPolicy.new(@order_detail).user_did_resolve?
  end

  def load_and_authorize_reservation
    @reservation = current_user.reservations.find(params[:id])
    @order_detail = @reservation.order_detail

    raise ActiveRecord::RecordNotFound unless editable? || resolved?
    authorize! :update, @reservation
  end

  def ability_resource
    @reservation
  end

end
