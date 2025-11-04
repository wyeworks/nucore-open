# frozen_string_literal: true

class ProductNotificationsController < ApplicationController

  admin_tab :all
  before_action { @active_tab = "admin_products" }
  before_action :init_current_facility
  load_resource :product, through: :current_facility, find_by: :url_name

  layout "two_column"

  # GET /facilities/:facility_url/products/:product_url/notifications
  def show
  end

  # GET /facilities/:facility_url/products/:product_url/notifications/edit
  def edit
    authorize!(:edit, @product)
  end

  # POST /facilities/:facility_url/products/:product_user/notifications
  def update
    authorize!(:update, @product)

    if @product.update(notification_params)
      redirect_to({ action: :show }, notice: text("success"))
    else
      render :edit
    end
  end

  private

  def notification_params
    params.expect(
      product: [:training_request_contacts,
                :order_notification_recipients,
                :cancellation_email_recipients,
                :issue_report_recipients],
    )
  end

end
