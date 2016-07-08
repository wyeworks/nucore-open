require 'zip'

class OrderDetailStoredFilesController < ApplicationController

  customer_tab  :all

  before_action :authenticate_user!
  before_action :init_order_detail
  authorize_resource class: OrderDetail

  def sample_results
    redirect_to @order_detail.stored_files.sample_result.find(params[:id]).download_url
  end

  def sample_results_zip
    data = Zip::OutputStream.write_buffer do |stream|
      @order_detail.stored_files.sample_result.each do |file|
        stream.put_next_entry(file.name)
        stream << file.read
      end
    end

    data.rewind

    respond_to do |format|
      format.zip { send_data data.read, filename: "sample_results_#{@order_detail}.zip" }
    end

  ensure
    data.close if data
  end

  def template_results
    redirect_to @order_detail.stored_files.template_result.find(params[:id]).download_url
  end

  # GET /orders/:order_id/order_details/:order_detail_id/order_file
  def order_file
    raise ActiveRecord::RecordNotFound if @order_detail.product.stored_files.template.empty?
    @file = @order_detail.stored_files.new(file_type: "template_result")
  end

  # POST /orders/:order_id/order_details/:order_detail_id/upload_order_file
  def upload_order_file
    @file = @order_detail.stored_files.new(params[:stored_file])
    @file.file_type  = "template_result"
    @file.name       = "Order File"
    @file.product = @order_detail.product
    @file.created_by = session_user.id ## this is correct, session_user instead of acting_user

    if @file.save
      flash[:notice] = "Order File uploaded successfully" # TODO: I18n

      if @order_detail.order.to_be_merged?
        @order_detail.merge! # trigger the OrderDetailObserver callbacks
        redirect_to facility_order_path(@order_detail.facility, @order_detail.order.merge_order || @order_detail.order)
      else
        redirect_to(order_path(@order))
      end
    else
      flash.now[:error] = "An error was encountered while uploading the Order File" # TODO: I18n
      render :order_file
    end
  end

  # GET /orders/:order_id/order_details/:order_detail_id/remove_order_file
  def remove_order_file
    if @order_detail.stored_files.template_result.all?(&:destroy)
      flash[:notice] = "The uploaded Order File has been deleted successfully" # TODO: I18n
    else
      flash[:error] = "An error was encountered while deleting the uploaded Order File" # TODO: I18n
    end
    @order.invalidate!
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

end
