# frozen_string_literal: true

class AccessoriesController < ApplicationController

  load_resource :order
  load_resource :order_detail, through: :order

  before_action :authorize_order_detail
  before_action :load_product

  customer_tab :all
  layout -> { modal? ? false : "application" }
  before_action { @active_tab = "reservations" }

  def new
    accessorizer = Accessories::Accessorizer.new(@order_detail)
    # If being done by a facility admin, only show the accessories that haven't already been
    # added. To update accessories already added, they should use the normal order view.
    @order_details = core_manager_context? ? accessorizer.unpurchased_accessory_order_details : accessorizer.accessory_order_details
  end

  def create
    update_data = update_accessories
    @order_details = update_data.order_details

    if update_data.valid?
      flash[:notice] = t("controllers.accessories.create.success", accessories: helpers.pluralize(update_data.persisted_count, "accessory"))
      respond_success
    else
      render :new, status: 406
    end
  end

  private

  def update_accessories
    accessorizer = Accessories::Accessorizer.new(@order_detail)
    if core_manager_context?
      accessorizer.update_unpurchased_attributes(params[:accessories])
    else
      accessorizer.update_attributes(params[:accessories])
    end
  end

  # This controller is used both at /orders/XXX/order_details/XXX/accessories (normal user view) and
  # /facility_name/orders/XXX/order_details/XXX/accessories (core manager view). Determine if we're in
  # the facility admin's context
  def core_manager_context?
    current_facility.present?
  end

  def respond_success
    if modal?
      head :ok
    else
      redirect_to core_manager_context? ? [current_facility, @order] : reservations_path
    end
  end

  def ability_resource
    @order_detail
  end

  def authorize_order_detail
    authorize! :add_accessories, @order_detail
  end

  def load_product
    @product = @order_detail.product
  end

  def helpers
    ActionController::Base.helpers
  end

  def modal?
    request.xhr?
  end
  helper_method :modal?

end
