# frozen_string_literal: true

class ProblemReservationsController < ApplicationController

  customer_tab :all

  before_action :authenticate_user!
  before_action :load_and_authorize_reservation
  before_action :prevent_double_update, only: :update
  before_action { @active_tab = "reservations" }

  delegate :editable?, :resolved?, to: :problem_reservation_resolver

  def edit
    render :resolved if !editable? && resolved?
  end

  def update
    if problem_reservation_resolver.resolve(update_params.merge(current_user: current_user))
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

  def problem_reservation_resolver
    @problem_reservation_resolver ||= ProblemReservationResolver.new(@reservation)
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
