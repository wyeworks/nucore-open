class ProductsCommonController < ApplicationController

  customer_tab  :show
  admin_tab     :create, :destroy, :new, :edit, :index, :update, :manage
  before_filter :authenticate_user!, except: [:show]
  before_filter :check_acting_as, except: [:show]
  before_filter :init_current_facility
  before_filter :init_product, except: [:index, :new, :create]
  before_filter :store_fullpath_in_session

  include TranslationHelper
  load_and_authorize_resource except: [:show, :manage]

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

    # not sure this actually does anything since @products is a Relation, not an Array, but it was
    # in ServicesController, ItemsController, and InstrumentsController before I pulled #index up
    # into this class
    @products.sort!

    render "admin/products/index"
  end

  # GET /facilities/:facility_id/(services|items|bundles)/:(service|item|bundle)_id
  # TODO InstrumentsController#show has a lot in common; refactor/extract/consolidate
  def show
    assert_product_is_accessible!
    add_to_cart = true
    @login_required = false

    # does the product have active price policies?
    unless @product.available_for_purchase?
      add_to_cart = false
      @error = "not_available"
    end

    # is user logged in?
    if add_to_cart && acting_user.blank?
      @login_required = true
      add_to_cart = false
    end

    # when ordering on behalf of, does the staff have permissions for this facility?
    if add_to_cart && acting_as? && !session_user.operator_of?(@product.facility)
      add_to_cart = false
      @error = "not_authorized_acting_as"
    end

    # does the user have a valid payment source for purchasing this reservation?
    if add_to_cart && acting_user.accounts_for_product(@product).blank?
      add_to_cart = false
      @error = "no_accounts"
    end

    # does the product have any price policies for any of the groups the user is a member of?
    if add_to_cart && !price_policy_available_for_product?
      add_to_cart = false
      @error = "not_in_price_group"
    end

    # is the user approved?
    if add_to_cart && !@product.can_be_used_by?(acting_user) && !session_user_can_override_restrictions?(@product)
      if SettingsHelper.feature_on?(:training_requests)
        if TrainingRequest.submitted?(session_user, @product)
          flash[:notice] = text(".already_requested_access", product: @product)
          return redirect_to facility_path(current_facility)
        else
          return redirect_to new_facility_product_training_request_path(current_facility, @product)
        end
      else
        add_to_cart = false
        @error = "requires_approval"
      end
    end

    if @error
      flash.now[:notice] = text(@error, singular: @product.class.model_name.downcase,
                                        plural: @product.class.model_name.human(count: 2).downcase)
    end

    @add_to_cart = add_to_cart
    @active_tab = "home"
    render layout: "application"
  end

  # GET /services/new
  def new
    @product = current_facility_products.new(account: Settings.accounts.product_default)
    save_product_into_object_name_instance
  end

  # POST /services
  def create
    @product = current_facility_products.new(params[:"#{singular_object_name}"])
    @product.initial_order_status_id = OrderStatus.default_order_status.id

    save_product_into_object_name_instance

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
      if @product.update_attributes(params[:"#{singular_object_name}"])
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

  protected

  def translation_scope
    "controllers.products_common"
  end

  private

  def assert_product_is_accessible!
    raise NUCore::PermissionDenied unless product_is_accessible?
  end

  def product_is_accessible?
    is_operator = session_user && session_user.operator_of?(current_facility)
    !(@product.is_archived? || (@product.is_hidden? && !is_operator))
  end

  # The equivalent of calling current_facility.services or current_facility.items
  def current_facility_products
    current_facility.send(:"#{plural_object_name}")
  end

  def price_policy_available_for_product?
    groups = (acting_user.price_groups + acting_user.account_price_groups).flatten.uniq.collect(&:id)
    @product.can_purchase?(groups)
  end

  # Dynamically get the proper object from the database based on the controller name
  def init_product
    @product = current_facility_products.find_by_url_name!(params[:"#{singular_object_name}_id"] || params[:id])
    save_product_into_object_name_instance
  end

  def save_product_into_object_name_instance
    instance_variable_set("@#{singular_object_name}", @product)
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

  def session_user_can_override_restrictions?(product)
    session_user.present? && session_user.can_override_restrictions?(product)
  end

end
