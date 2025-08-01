# frozen_string_literal: true

class OrderStatusesController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource through: :current_facility
  # Disallow editing root statuses
  before_action :ensure_editable, only: [:edit, :update, :destroy]

  layout "two_column"

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /order_statuses
  def index
    @order_statuses       = current_facility.order_statuses.sorted
  end

  # GET /order_statuses/new
  def new
    @order_status.facility = current_facility
  end

  # GET /facilities/:facility_id/order_statuses/:id/edit
  def edit
  end

  # POST /order_statuses
  def create
    @order_status.facility = current_facility

    if @order_status.save
      flash[:notice] = "The Order Status was successfully created."
      redirect_to facility_order_statuses_url
    else
      render action: "new"
    end
  end

  # PUT /facilities/:facility_id/order_statuses/:id
  def update
    if @order_status.update(update_params)
      flash[:notice] = "The Order Status was successfully updated."
      redirect_to facility_order_statuses_path
    else
      render action: "edit"
    end
  end

  # DELETE /facilities/:facility_id/order_statuses/:id
  def destroy
    parent_status = @order_status.root
    @order_status.transaction do
      begin
        # used instead of update_all so vestal_versions can do its thing; annoying, I know
        @order_status.order_details.each { |os| os.update_attribute(:order_status, parent_status) }
        @order_status.destroy
        flash[:notice] = "The order status was successfully removed."
      rescue => e
        flash[:error] = "An error was encountered while removing the order status."
        raise ActiveRecord::Rollback
      end
    end
    redirect_to facility_order_statuses_url
  end

  private

  def create_params
    params.require(:order_status).permit(:name, :parent_id)
  end

  def update_params
    params.require(:order_status).permit(:name)
  end

  def ensure_editable
    raise ActiveRecord::RecordNotFound unless @order_status.editable?
  end

end
