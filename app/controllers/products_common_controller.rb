# frozen_string_literal: true

class ProductsCommonController < ApplicationController

  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_action :authenticate_user!, except: [:show]
  before_action :check_acting_as, except: [:show]
  before_action :init_current_facility
  before_action :init_product, except: [:index, :new, :create]
  before_action :store_fullpath_in_session

  include TranslationHelper

  load_resource except: [:show, :manage, :index], instance_name: :product
  authorize_resource except: [:show, :manage], instance_name: :product

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /services
  def index
    @archived_product_count     = current_facility_products.archived.length
    @not_archived_product_count = current_facility_products.not_archived.length
    @products = if params[:archived].nil? || params[:archived] != "true"
                  current_facility_products.not_archived
                else
                  current_facility_products.archived
                end

    render "admin/products/index"
  end

  # GET /facilities/:facility_id/(services|items|bundles)/:(service|item|bundle)_id
  def show
    @active_tab = "home"
    product_for_cart = ProductForCart.new(@product)
    @add_to_cart = product_for_cart.purchasable_by?(acting_user, session_user)

    if product_for_cart.error_path
      redirect_to product_for_cart.error_path, notice: product_for_cart.error_message
    else
      flash.now[:notice] = product_for_cart.error_message if product_for_cart.error_message
      render layout: "application"
    end
  end

  # GET /services/new
  def new
    @product = current_facility_products.new(account: Settings.accounts.product_default)
  end

  # POST /services
  def create
    @product = current_facility_products.new(resource_params)
    @product.initial_order_status_id = OrderStatus.default_order_status.id

    if @product.save
      flash[:notice] = "#{@product.class.name} was successfully created."
      redirect_to([:manage, current_facility, @product])
    else
      render action: "new"
    end
  end

  # GET /facilities/alpha/(items|services|instruments)/1/edit
  def edit
  end

  # PUT /services/1
  def update
    respond_to do |format|
      if @product.update_attributes(resource_params)
        flash[:notice] = "#{@product.class.name.capitalize} was successfully updated."
        format.html { redirect_to([:manage, current_facility, @product]) }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /services/1
  def destroy
    if @product.destroy
      flash[:notice] = "#{@product.class.name} was successfully deleted"
    else
      flash[:error] = "There was a problem deleting the #{@product.class.name.to_lower}"
    end
    redirect_to [current_facility, plural_object_name]
  end

  def manage
    authorize! :view_details, @product
    @active_tab = "admin_products"
  end

  private

  def resource_params
    params.require(:"#{singular_object_name}").permit(:name, :url_name, :contact_email, :description,
                                                      :facility_account_id, :account, :initial_order_status_id,
                                                      :requires_approval, :allows_training_requests, :is_archived, :is_hidden, :email_purchasers_on_order_status_changes,
                                                      :user_notes_field_mode, :user_notes_label, :show_details,
                                                      :schedule_id, :control_mechanism, :reserve_interval,
                                                      :min_reserve_mins, :max_reserve_mins, :min_cancel_hours,
                                                      :auto_cancel_mins, :lock_window, :cutoff_hours,
                                                      :problems_resolvable_by_user,
                                                      relay_attributes: [:ip, :ip_port, :outlet, :username, :password, :type,
                                                                         :auto_logout, :auto_logout_minutes, :id])
  end

  def current_facility_products
    product_class.where(facility: current_facility).alphabetized
  end

  # Dynamically get the proper object from the database based on the controller name
  def init_product
    @product = current_facility_products.find_by!(url_name: params[:"#{singular_object_name}_id"] || params[:id])
  end

  def product_class
    self.class.name.gsub(/Controller$/, "").singularize.constantize
  end
  helper_method :product_class

  # Get the object name to work off of. E.g. In ServicesController, this returns "services"
  def plural_object_name
    singular_object_name.pluralize
  end
  helper_method :plural_object_name

  def singular_object_name
    product_class.to_s.underscore
  end
  helper_method :singular_object_name

end
