# frozen_string_literal: true

class ProductUsersController < ApplicationController

  include SearchHelper
  include BelongsToProductController

  admin_tab :index, :new
  before_action :init_product_user

  load_and_authorize_resource

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /facilities/:facility_id/bundles/bundle_id/users
  # GET /facilities/:facility_id/instruments/instrument_id/users
  # GET /facilities/:facility_id/items/item_id/users
  # GET /facilities/:facility_id/services/service_id/users
  def index
    if @product.requires_approval?
      @product_users = @product
                       .product_users
                       .includes(:user)
                       .order("users.last_name ASC", "users.first_name ASC")
                       .paginate(page: params[:page])
    else
      @product_users = nil
      flash.now[:notice] = text("index.not_required", model: downcase_product_type)
    end
  end

  # GET /facilities/:facility_id/bundles/bundle_id/users/new
  # GET /facilities/:facility_id/instruments/instrument_id/users/new
  # GET /facilities/:facility_id/items/item_id/users/new
  # GET /facilities/:facility_id/services/service_id/users/new
  def new
    return unless params[:user]
    product_user = ProductUserCreator.create(user: User.find(params[:user]), product: @product, approver: session_user)
    if product_user.persisted?
      LogEvent.log(product_user, :create, session_user)
      flash[:notice] = text("new.success", model: downcase_product_type)
    else
      flash[:error] = product_user.errors.full_messages.to_sentence
    end
    redirect_to action: :index
  end

  # DELETE /facilities/:facility_id/bundles/bundle_id/users/:id
  # DELETE /facilities/:facility_id/instruments/instrument_id/users/:id
  # DELETE /facilities/:facility_id/items/item_id/users/:id
  # DELETE /facilities/:facility_id/services/service_id/users/:id
  def destroy
    product_user = ProductUser.find_by(product_id: @product.id, user_id: params[:id])

    if product_user.blank?
      # Show success even if it doesn't exist because it is likely to be a
      # multi-tab issue
      flash[:notice] = text("destroy.success", model: downcase_product_type)
    elsif product_user.destroy
      LogEvent.log(product_user, :delete, session_user)
      flash[:notice] = text("destroy.success", model: downcase_product_type)
    else
      flash[:error]  = text("destroy.failure", model: downcase_product_type)
    end

    redirect_to action: :index
  end

  # PUT /facilities/:facility_id/instruments/:instrument_id/update_restrictions
  def update_restrictions
    permitted_params = params.require(@product.class.name.underscore).require(:product_users)

    unless permitted_params
      redirect_to action: :index
      return
    end
    permitted_params.each do |product_user_id, product_access_group_params|
      product_user = @product.product_users.find(product_user_id)
      product_user.update_attributes(product_access_group_params.permit(:product_access_group_id))
    end

    flash[:notice] = text("update_restrictions.success")
    redirect_to action: :index
  end

  private

  def downcase_product_type
    @product.class.model_name.human.downcase
  end

  def init_product_user
    @product_user = @product.product_users.build # for CanCan auth
  end

end
