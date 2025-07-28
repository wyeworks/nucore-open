# frozen_string_literal: true

class ProductAccessoriesController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product
  load_and_authorize_resource through: :product

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  def index
    @product_accessory = ProductAccessory.new product: @product
    set_available_accessories
  end

  def create
    if @product_accessory.save
      flash[:notice] = I18n.t("product_accessories.create.success")
    else
      flash[:error] = I18n.t("product_accessories.create.error")
    end
    redirect_to action: :index
  end

  def destroy
    @product_accessory.soft_delete
    flash[:notice] = I18n.t("product_accessories.destroy.success")
    redirect_to action: :index
  end

  private

  def create_params
    params.require(:product_accessory).permit(:accessory_id, :scaling_type)
  end

  def init_product
    @product = current_facility.products.find_by!(url_name: params[:product_id])
  end

  def set_available_accessories
    # Exclude already included accessories as well as the current product.
    non_available_accessories = [@product.id] + Array(@product_accessories).map(&:accessory_id)
    @available_accessories = current_facility.products.accessorizable.not_archived.exclude(non_available_accessories).order(:name)
  end

end
