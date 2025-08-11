# frozen_string_literal: true

class FacilityOrderDetailsController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_order_detail

  load_and_authorize_resource class: OrderDetail

  def initialize
    @active_tab = "admin_orders"
    super
  end

  def show
    respond_to do |format|
      format.html do
        # This is deprecated in favor of OrderManagement::OrderDetailsController, but
        # we want to avoid 404s
        redirect_to facility_order_path(current_facility, @order)
      end

      format.ics do
        calendar = ReservationCalendar.new(@order_detail.reservation)
        send_data(calendar.to_ical,
                  type: "text/calendar", disposition: "attachment",
                  filename: calendar.filename)
      end
    end
  end

  def destroy
    redirect_to_order = @order.merge_order

    if @order.to_be_merged?
      begin
        @order_detail.destroy
        flash[:notice] = I18n.t "controllers.facility_order_details.destroy.success"
      rescue => e
        Rails.logger.error "#{e.message}:#{e.backtrace.join("\n")}"
        flash[:error] = I18n.t "controllers.facility_order_details.destroy.error", order_detail_id: @order_detail.to_s
      end
    else
      flash[:notice] = I18n.t "controllers.facility_order_details.destroy.notice"
      redirect_to_order = @order
    end

    if @order_detail.order.cross_core_project.present?
      redirect_back(fallback_location: root_path)
    else
      redirect_to facility_order_path(current_facility, redirect_to_order)
    end
  end

  private

  def process_account_change
    return if params[:order_detail][:account_id].to_i == @order_detail.account_id
    @order_detail.account = Account.find(params[:order_detail][:account_id])
    @order_detail.statement = nil
    @order_detail.save!
  end

  def set_active_tab
    @active_tab = if @order_detail.reservation
                    "admin_reservations"
                  else
                    "admin_orders"
                  end
  end

  def init_order_detail
    @order = Order.find(params[:order_id])
    raise ActiveRecord::RecordNotFound unless @order
    @order_detail = @order.order_details.find(params[:id] || params[:order_detail_id])
  end

end
