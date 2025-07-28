# frozen_string_literal: true

require "zip"

class OrderDetailStoredFilesController < ApplicationController

  customer_tab  :all

  before_action :init_order_detail
  authorize_resource class: OrderDetail

  def sample_results
    redirect_to @order_detail.stored_files.sample_result.find(params[:id]).download_url
  end

  def sample_results_zip
    zip_data = StoredFileZipper.new(@order_detail.stored_files.sample_result).read

    respond_to do |format|
      format.zip { send_data zip_data, filename: "sample_results_#{@order_detail}.zip" }
    end
  end

  def template_results
    redirect_to @order_detail.stored_files.template_result.find(params[:id]).download_url
  end

  # GET /orders/:order_id/order_details/:order_detail_id/order_file
  def order_file
    @original_order_id = params[:original_order_id]
    raise ActiveRecord::RecordNotFound if @order_detail.product.stored_files.template.empty?
    @file = @order_detail.stored_files.new(file_type: "template_result")
  end

  # POST /orders/:order_id/order_details/:order_detail_id/upload_order_file
  def upload_order_file
    @original_order_id = params[:original_order_id]
    @file = @order_detail.stored_files.new(params[:stored_file]&.permit(:file))
    @file.file_type  = "template_result"
    @file.name       = "Order File"
    @file.product = @order_detail.product
    @file.created_by = session_user.id ## this is correct, session_user instead of acting_user

    if @file.save
      flash[:notice] = text("upload_order_file.success")

      if @order_detail.order.to_be_merged?
        @order_detail.save! # trigger the OrderDetailObserver callbacks
        redirect_to_facility_order(consider_merge_order: true)
      else
        redirect_to(order_path(@order))
      end
    else
      flash.now[:error] = text("upload_order_file.error")
      render :order_file
    end
  end

  # GET /orders/:order_id/order_details/:order_detail_id/remove_order_file
  def remove_order_file
    if @order.purchased?
      flash[:error] = text("remove_order_file.already_purchased_error")
    else
      if @order_detail.stored_files.template_result.all?(&:destroy)
        flash[:notice] = text("remove_order_file.success")
      else
        flash[:error] = text("remove_order_file.delete_error")
      end
      @order.invalidate!
    end
    redirect_to(order_path(@order))
  end

  private

  def init_order_detail
    @order = Order.find(params[:order_id])
    @order_detail = @order.order_details.find(params[:order_detail_id])
  end

  def ability_resource
    @order_detail
  end

  def redirect_to_facility_order(consider_merge_order: false)
    if @original_order_id.present?
      original_order = Order.find(@original_order_id)

      order = consider_merge_order ? original_order.merge_order || original_order : original_order

      redirect_to facility_order_path(original_order.facility, order)
    else
      order = consider_merge_order ? @order_detail.order.merge_order || @order_detail.order : @order_detail.order

      redirect_to facility_order_path(@order_detail.facility, order)
    end
  end

end
