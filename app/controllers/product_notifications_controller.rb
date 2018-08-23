class ProductNotificationsController < ApplicationController

  admin_tab :all
  before_action { @active_tab = "admin_products" }
  before_action :authenticate_user!
  before_action :init_current_facility
  load_resource :product, through: :current_facility, find_by: :url_name

  layout "two_column"

  # GET /facilities/:facility_url/products/:product_url/notifications
  def edit
    authorize!(:edit, @product)
  end

  # POST /facilities/:facility_url/products/:product_user/notifications
  def update
    authorize!(:update, @product)

    if @product.update(notification_params)
      redirect_to({ action: :index }, notice: text("success"))
    else
      render :index
    end
  end

  private

  def notification_params
    params.require(:product).permit(
      :training_request_contacts,
      :order_notification_recipient,
      :cancellation_notification_contacts,
    )
  end

end
