# frozen_string_literal: true

class FacilityUserReservationsController < ApplicationController

  admin_tab :all
  before_action :init_current_facility
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :load_user
  before_action :load_order_detail, only: :cancel

  load_and_authorize_resource class: "OrderDetail"

  layout "two_column"

  # GET /facilities/:facility_id/users/:user_id/reservations
  def index
    @order_details = user_order_details
                     .purchased
                     .order(ordered_at: :desc)
                     .paginate(page: params[:page])
  end

  # PUT /facilities/:facility_id/users/:user_id/reservations/:order_detail_id/cancel
  def cancel
    reservation = @order_detail.reservation
    raise ActiveRecord::RecordNotFound if reservation.blank?

    unless reservation.canceled?
      raise ActiveRecord::RecordNotFound unless reservation.can_cancel?
      cancel_with_fee!
    end

    if reservation.canceled?
      flash[:notice] = text("cancel.success")
    else
      flash[:error] = text("cancel.error")
    end

    redirect_to facility_user_reservations_path(current_facility, @user)
  end

  private

  def cancel_with_fee!
    @order_detail.transaction do
      unless @order_detail.cancel_reservation(session_user, admin: true, admin_with_cancel_fee: true)
        raise ActiveRecord::Rollback
      end
    end
  end

  def load_user
    @user = User.find(params[:user_id])
  end

  def load_order_detail
    @order_detail = user_order_details.find(params[:order_detail_id])
  end

  def user_order_details
    @user.order_details.reservations.for_facility(current_facility)
  end

end
