# frozen_string_literal: true

class FacilitiesController < ApplicationController

  customer_tab :index, :list, :show
  admin_tab :edit, :manage, :update, :transactions,
            :reassign_chart_strings, :movable_transactions,
            :confirm_transactions, :move_transactions, :disputed_orders
  skip_before_action :authenticate_user!, only: [:index, :show] # public pages do not require authentication
  before_action :check_acting_as, except: [:index, :show]
  before_action :set_admin_billing_tab, only: [:confirm_transactions, :disputed_orders, :movable_transactions, :transactions] # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :store_fullpath_in_session, only: [:index, :show]
  before_action :enable_sorting, only: [:disputed_orders, :movable_transactions, :transactions] # rubocop:disable Rails/LexicallyScopedActionFilter

  around_action :allow_granted_permission_users, only: [:list, :dashboard]
  load_and_authorize_resource find_by: :url_name
  skip_load_and_authorize_resource only: [:index, :show]

  include AZHelper
  include MovableTransactions
  include OrderDetailsCsvExport
  include SortableBillingTable

  layout lambda {
    action_name.in?(%w(disputed_orders movable_transactions transactions)) ? "two_column_head" : "two_column"
  }

  cattr_accessor(:facility_homepage_redirector) { DefaultFacilityHomepageRedirector }

  # GET /facilities/:facility_url/dashboard
  def dashboard
    redirect_to facility_homepage_redirector.redirect_path(current_facility, current_user)
  end

  # GET /facilities
  def index
    @facilities = Facility.active.alphabetized
    @recently_used_facilities = MostRecentlyUsedSearcher.new(acting_user).recently_used_facilities.alphabetized
    @active_tab = SettingsHelper.feature_on?(:use_manage) ? "use" : "home"
    @list_layout = SettingsHelper.feature_on?(:facility_tile_list) ? "tile" : "list"
    @recent_products = MostRecentlyUsedSearcher.new(acting_user).recently_used_products.includes(:facility).alphabetized
    @azlist = build_az_list(@facilities)
    render layout: "application"
  end

  # GET /facilities/:facility_id
  def show
    return redirect_to(facilities_path) if current_facility.try(:cross_facility?)
    raise ActiveRecord::RecordNotFound unless current_facility.try(:is_active?)
    @columns = "columns" if SettingsHelper.feature_on?(:product_list_columns)
    @active_tab = SettingsHelper.feature_on?(:use_manage) ? "use" : "home"

    @product_scope = Product.alphabetized
    if acting_as? || session_user.try(:operator_of?, current_facility)
      @product_scope = @product_scope.not_archived
    else
      @product_scope = @product_scope.active # Active also excludes hidden
    end

    @product_display_groups = current_facility.product_display_groups.sorted
    @product_display_groups = @product_display_groups.to_a + ProductDisplayGroup.fake_groups_by_type(current_facility.products.without_display_group)

    render layout: "application"
  end

  # GET /facilities/list
  def list
    # show list of operable facilities for current user, and admins manage all facilities
    @active_tab = "manage_facilites"
    if session_user.administrator?
      facilities = Facility.alphabetized
      @active_facilities = facilities.active
      @inactive_facilities = facilities.inactive
      flash.now[:notice] = "No facilities have been added" if facilities.empty?
    else
      facilities = operable_facilities
      @active_facilities = facilities.active
      @inactive_facilities = facilities.inactive
      raise ActiveRecord::RecordNotFound if facilities.empty?
      if facilities.size == 1
        redirect_to dashboard_facility_path(facilities.first)
        return
      end
    end

    render layout: "application"
  end

  # GET /facilities/:facility_id/manage
  def manage
    @active_tab = "admin_facility"
  end

  # GET /facilities/new
  def new
    @active_tab = "manage_facilites"
    @facility = Facility.new
    @facility.is_active = true

    render layout: "application"
  end

  # GET /facilities/:facility_id/edit
  def edit
    @active_tab = "admin_facility"
  end

  # POST /facilities
  def create
    @active_tab = "manage_facilites"
    @facility = Facility.new(facility_params)

    if @facility.save
      flash[:notice] = text("create.success")
      redirect_to manage_facility_path(@facility)
    else
      render action: "new", layout: "application"
    end
  end

  # PUT /facilities/:facility_id
  def update
    if current_facility.update(facility_params)
      flash[:notice] = text("update.success")
      redirect_to manage_facility_path(current_facility)
    else
      render action: "edit"
    end
  end

  # GET /facilities/:facility_id/transactions
  def transactions
    order_details = OrderDetail.purchased.for_facility(current_facility)
    @export_enabled = true

    @search_form = TransactionSearch::SearchForm.new(
      params[:search],
      defaults: {
        date_range_start: format_usa_date(1.month.ago.beginning_of_month),
      },
    )

    @search =
      TransactionSearch::Searcher
      .new(facilities: current_facility.cross_facility?)
      .search(order_details, @search_form)

    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.joins(order: :user)
                            .includes(order: [:user, :facility])
                            .includes(:account, :product, :order_status, :created_by_user, :statement, :price_policy, :journal, :external_service_receiver, :bundle, :project)
                            .includes(:reservation)
                            .preload(account: :owner_user)
                            .reorder(sort_clause)

    respond_to do |format|
      format.html do
        @grand_total = @order_details.grand_total
        @order_details = @order_details.paginate(page: params[:page]).order(:id)
      end
      format.csv { handle_csv_search }
    end
  end

  # GET /facilities/:facility_id/disputed_orders
  def disputed_orders
    order_details = OrderDetail.in_dispute.for_facility(current_facility)

    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search =
      TransactionSearch::Searcher
      .new(facilities: current_facility.cross_facility?)
      .search(order_details, @search_form)

    @date_range_field = @search_form.date_params[:field]
    @extra_date_column = :dispute_at
    params[:dir] = "asc" if params[:dir].nil? # default to "asc"
    @order_details = @search.order_details.reorder(sort_clause).paginate(page: params[:page])
  end

  private

  def allow_granted_permission_users
    yield
  rescue CanCan::AccessDenied
    raise unless current_user&.facility_user_permissions&.any?

    case action_name
    when "list"
      list
    when "dashboard"
      redirect_to facility_facility_users_path(current_facility)
    else
      raise
    end
  end

  def include_facilities?
    current_facility.cross_facility?
  end

  def movable_transactions_order_details
    OrderDetail.all_movable.for_facility(current_facility)
  end

  def redirect_to_movable_transactions
    redirect_to facility_movable_transactions_path(current_facility)
  end

  def facility_params
    params.require(:facility).permit(*self.class.permitted_facility_params)
  end

  cattr_accessor(:permitted_facility_params) do
    %i(
      abbreviation
      accepts_multi_add
      address
      banner_notice
      description
      email
      fax_number
      is_active
      show_order_note
      name
      order_notification_recipient
      phone_number
      short_description
      show_instrument_availability
      url_name
      dashboard_enabled
      kiosk_enabled
      payment_url
      file
      remove_file
    )
  end

  def initialize_chart_string_reassignment_form
    @chart_string_reassignment_form = ChartStringReassignmentForm.new(@order_details)
    @date_range_field = "journal_or_statement_date"
  end

  def set_admin_billing_tab
    @active_tab = "admin_billing"
  end

  def azlist_on?
    SettingsHelper.feature_on?(:azlist)
  end
  helper_method :azlist_on?

end
