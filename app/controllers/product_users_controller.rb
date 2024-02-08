# frozen_string_literal: true

class ProductUsersController < ApplicationController

  include SearchHelper
  include CsvEmailAction
  include BelongsToProductController

  admin_tab :index, :new
  before_action :init_product_user

  load_and_authorize_resource

  layout "two_column"

  USERS_PER_PAGE = 50

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
      respond_to do |format|
        format.csv do
          # used for "Export as CSV" link
          yield_email_and_respond_for_report do |email|
            access_list_report = Reports::ProductAccessListCsvReport.new(@product.name, all_product_users)
            CsvReportMailer.csv_report_email(email, access_list_report).deliver
          end
        end

        format.html do
          @product_users = all_product_users.paginate(page: params[:page], per_page: USERS_PER_PAGE)
        end
      end
    else
      @product_users = nil
      flash.now[:notice] = text("index.not_required", model: downcase_product_type)
    end
  end

  # GET /facilities/:facility_id/bundles/bundle_id/users/search
  # GET /facilities/:facility_id/instruments/instrument_id/users/search
  # GET /facilities/:facility_id/items/item_id/users/search
  # GET /facilities/:facility_id/services/service_id/users/search
  def search
    @product_users = all_product_users(params[:search]).paginate(page: params[:page], per_page: USERS_PER_PAGE)

    @search_term = params[:search]

    render layout: false
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
      product_user.update(product_access_group_params.permit(:product_access_group_id))
    end

    flash[:notice] = text("update_restrictions.success")
    redirect_to action: :index
  end

  private

  def all_product_users(search_term = nil)
    product_users = @product
                    .product_users
                    .includes(:user)
                    .includes(:product_access_group)

    if search_term.present?
      product_users = product_users.where("LOWER(users.last_name) LIKE :search OR LOWER(users.first_name) LIKE :search OR LOWER(users.username) LIKE :search", search: search_term.downcase)
    end

    product_users.order("users.last_name ASC", "users.first_name ASC")
  end

  def downcase_product_type
    @product.class.model_name.human.downcase
  end

  def init_product_user
    @product_user = @product.product_users.build # for CanCan auth
  end

end
