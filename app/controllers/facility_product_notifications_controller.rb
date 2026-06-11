# frozen_string_literal: true

##
# Manage ProductNotification for a facility
class FacilityProductNotificationsController < ApplicationController
  admin_tab :all
  layout "two_column"
  load_and_authorize_resource(
    instance_name: :product_notification,
    throught: :current_facility,
    class: ProductNotification,
  )

  def show
  end

  def new
    @product_notification = ProductNotification.new
  end

  def create
    if @product_notification.save
      flash[:notice] = t(".success")
      redirect_to :show
    else
      flash[:notice] = t(".error")
      render :new
    end
  end

  def edit
  end

  def update
    if @product_notification.update(product_notification_params)
      flash[:notice] = t(".success")
      redirect_to :show
    else
      flash.now[:error] = t(".error")
      render :edit
    end
  end

  def index
    @product_notifications =
      current_facility
      .product_notifications
      .includes(:products)
      .paginate(page: params[:page])
  end

  def destroy
    @product_notification.destroy
    flash[:notice] = t(".success")
    redirect_to :index
  end

  private

  def product_notification_params
    params.require(:product_notification).permit(
      :reservation_days,
      :user_ids,
      :product_ids,
    ).merge(facility_id: current_facility.id)
  end
end
