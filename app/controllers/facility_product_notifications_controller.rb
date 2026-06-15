# frozen_string_literal: true

##
# Manage ProductNotification for a facility
class FacilityProductNotificationsController < ApplicationController
  admin_tab :all
  layout "two_column"
  load_and_authorize_resource(
    instance_name: :product_notification,
    through: :current_facility,
    through_association: :product_notifications,
    class: ProductNotification,
  )

  before_action :load_instruments, only: [:new, :edit]

  def show
  end

  def new
    @product_notification = ProductNotification.new
  end

  def create
    if @product_notification.save
      flash[:notice] = t(".success")
      redirect_to action: :show, id: @product_notification
    else
      flash.now[:error] = t(".error")
      render :new
    end
  end

  def edit
  end

  def update
    if @product_notification.update(facility_product_notification_params)
      flash[:notice] = t(".success")
      redirect_to action: :show
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
    redirect_to action: :index
  end

  # TODO: Check permissions and Users that can be searched
  def user_search
    @users = UserFinder.search(params[:search_term], limit: 25)
    render partial: "user_search_results", layout: false
  end

  private

  def load_instruments
    @instruments =
      current_facility
      .products
      .active
      .not_archived
      .of_type(Instrument)
      .alphabetized
  end

  def facility_product_notification_params
    params.require(:product_notification).permit(
      :name,
      :reservation_days,
      :email_subject,
      user_ids: [],
      product_ids: [],
    ).merge(facility_id: current_facility.id)
  end
end
