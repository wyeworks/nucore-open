class ProductAccessoriesController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
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
    @product.product_accessories.create(params[:product_accessory])
    flash[:notice] = I18n.t("product_accessories.create.success")
    redirect_to action: :index
  end

  def destroy
    @product_accessory.soft_delete
    flash[:notice] = I18n.t("product_accessories.destroy.success")
    redirect_to action: :index
  end

  private

  def init_product
    @product = current_facility.products.find_by_url_name!(params[:product_id])
  end

  def set_available_accessories
    # Already set as an accessory, or is this instrument
    non_available_accessories = [@product.id] + Array(@product_accessories).map(&:accessory_id)
    @available_accessories = current_facility.products.accessorizable.exclude(non_available_accessories).order(:name)
  end

end
