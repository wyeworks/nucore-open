# frozen_string_literal: true

class KioskAccessoriesController < ApplicationController

  skip_before_action :authenticate_user!
  load_resource :order
  load_resource :order_detail, through: :order

  before_action :load_product_and_reservation

  include ReservationSwitch

  layout false

  def new
    @switch = params[:switch]
    @order_details = accessorizer.accessory_order_details
  end

  def create
    respond_error(text("authentication.error")) && return unless can_create?

    update_data = update_accessories
    @order_details = update_data.order_details
    if update_data.valid?
      @persisted_count = update_data.persisted_count
      if params[:switch] == "off"
        switch_instrument!(params[:switch])
      else
        flash[:notice] = text("create.success", accessories: helpers.pluralize(@persisted_count, "accessory"))
      end
      head :ok
    else
      respond_error(text("create.error"))
    end
  end

  private

  def can_create?
    password = params.dig(:kiosk_accessories, :password)
    kiosk_user = Users::AuthChecker.new(@reservation.user, password)
    kiosk_user.authenticated? && kiosk_user.authorized?(:add_accessories, @order_detail)
  end

  def switch_off_success
    text("create.switch_off", accessories: helpers.pluralize(@persisted_count, "accessory"))
  end

  def respond_error(message)
    @order_details = accessorizer.build_order_details_from(params[:kiosk_accessories])
    @switch = params[:switch]
    flash.now[:error] = message
    render :new, status: 406, layout: false
  end

  def update_accessories
    accessorizer.update_accessorizer_attributes(params[:kiosk_accessories])
  end

  def accessorizer
    @accessorizer ||= Accessories::Accessorizer.new(@order_detail)
  end

  def ability_resource
    @order_detail
  end

  def load_product_and_reservation
    @product = @order_detail.product
    @reservation = Reservation.find(@order_detail.reservation.id)
  end

end
