# frozen_string_literal: true

class FacilityOrdersController < ApplicationController

  include SortableColumnController
  include NewInprocessController
  include ProblemOrderDetailsController
  include TabCountHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  before_action :load_order, only: [:show, :update, :send_receipt]
  before_action :load_merge_orders, only: [:show, :update]
  before_action :load_add_to_order_form, only: [:show, :update]

  load_and_authorize_resource class: Order

  def initialize
    @active_tab = "admin_orders"
    super
  end

  # GET /facility/1/orders
  # Provided by NewInprocessController
  # def index
  # end

  def show
    @order_details = @order.order_details.ordered_by_parents
    @order_details = @order_details.includes(:reservation, :order_status, :product, :order)
  end

  ## POST /facilities/:facility_id/orders/batch_update
  def batch_update
    redirect_to facility_orders_path

    msg_hash = batch_updater.update!

    # add flash messages if necessary
    flash.merge!(msg_hash) if msg_hash
  end

  def send_receipt
    begin
      PurchaseNotifier.order_receipt(order: @order, user: @order.user).deliver_later
      flash[:notice] = "Receipt sent successfully."
    rescue => e
      flash[:error] = "There was a problem while sending the receipt: #{e.message}"
    end

    redirect_fallback = @order ? facility_order_path(current_facility, @order) : root_path
    redirect_back(fallback_location: redirect_fallback)
  end

  # PUT/PATCH /facilities/:facility_id/orders/:id
  def update
    @add_to_order_form.assign_attributes(add_to_order_params.merge(created_by: current_user))
    if @add_to_order_form.save
      if @add_to_order_form.notifications?
        flash[:error] = @add_to_order_form.notifications_message
      else
        flash[:notice] = @add_to_order_form.success_message
      end
      redirect_to facility_order_path(current_facility, @order)
    else
      flash.now[:error] = @add_to_order_form.error_message
      show # set @order_details
      render :show
    end
  end

  protected

  def show_problems_path
    show_problems_facility_orders_path
  end

  private

  def add_to_order_params
    params.require(:add_to_order_form).permit(:quantity, :product_id, :order_status_id, :note, :fulfilled_at, :duration, :account_id, :reference_id)
  end

  def batch_updater
    @batch_updater ||= OrderDetailBatchUpdater.new(params[:order_detail_ids], current_facility, session_user, params)
  end

  def load_order
    @order = current_facility.orders.find params[:id]
  end

  def load_merge_orders
    @merge_orders = Order.where(merge_with_order_id: @order.id, created_by: current_user.id)
  end

  def load_add_to_order_form
    @add_to_order_form = AddToOrderForm.new(@order)
  end

  def new_or_in_process_orders
    # will never include instrument order details
    current_facility.order_details
                    .new_or_inprocess
                    .item_and_service_orders
  end

  def problem_order_details
    current_facility.problem_plain_order_details
  end

end
