# frozen_string_literal: true

class FacilitiesController < ApplicationController

  customer_tab :index, :list, :show
  admin_tab :edit, :manage, :update, :transactions,
            :reassign_chart_strings, :movable_transactions,
            :confirm_transactions, :move_transactions, :disputed_orders
  before_action :authenticate_user!, except: [:index, :show] # public pages do not require authentication
  before_action :check_acting_as, except: [:index, :show]
  before_action :load_order_details, only: [:confirm_transactions, :move_transactions, :reassign_chart_strings]
  before_action :set_admin_billing_tab, only: [:confirm_transactions, :disputed_orders, :movable_transactions, :transactions]
  before_action :store_fullpath_in_session, only: [:index, :show]

  load_and_authorize_resource find_by: :url_name
  skip_load_and_authorize_resource only: [:index, :show]

  include FacilitiesHelper
  include AZHelper
  include OrderDetailsCsvExport

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
    @recent_products = MostRecentlyUsedSearcher.new(acting_user).recently_used_products.includes(:facility).alphabetized
    @azlist = build_az_list(@facilities)
    render layout: "application"
  end

  # GET /facilities/:facility_id
  def show
    return redirect_to(facilities_path) if current_facility.try(:cross_facility?)
    raise ActiveRecord::RecordNotFound unless current_facility.try(:is_active?)
    @order_form = nil
    @order_form = Order.new if acting_user && current_facility.accepts_multi_add?
    set_column_class
    @active_tab = SettingsHelper.feature_on?(:use_manage) ? "use" : "home"
    render layout: "application"
  end

  # GET /facilities/list
  def list
    # show list of operable facilities for current user, and admins manage all facilities
    @active_tab = "manage_facilites"
    if session_user.administrator?
      @facilities = Facility.alphabetized
      flash.now[:notice] = "No facilities have been added" if @facilities.empty?
    else
      @facilities = operable_facilities
      raise ActiveRecord::RecordNotFound if @facilities.empty?
      if @facilities.size == 1
        redirect_to dashboard_facility_path(@facilities.first)
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
    if current_facility.update_attributes(facility_params)
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

    @search = TransactionSearch::Searcher.new.search(order_details, @search_form)
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details

    respond_to do |format|
      format.html { @order_details = @order_details.paginate(page: params[:page]) }
      format.csv { handle_csv_search }
    end
  end

  # GET /facilities/:facility_id/disputed_orders
  def disputed_orders
    order_details = OrderDetail.in_dispute.for_facility(current_facility)

    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.search(order_details, @search_form)
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.reorder(:dispute_at).paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/movable_transactions
  def movable_transactions
    @search_form = TransactionSearch::SearchForm.new(params[:search])
    @search = TransactionSearch::Searcher.new.search(
      OrderDetail.all_movable.for_facility(current_facility),
      @search_form,
    )
    @date_range_field = @search_form.date_params[:field]
    @order_details = @search.order_details.paginate(page: params[:page], per_page: 100)

    @order_detail_action = :reassign_chart_strings
  end

  # POST /facilities/:facility_id/movable_transactions/reassign_chart_strings
  def reassign_chart_strings
    ensure_order_details_selected
    initialize_chart_string_reassignment_form
  end

  # POST /facilities/:facility_id/movable_transactions/confirm
  def confirm_transactions
    load_transactions
    initialize_chart_string_reassignment_form
  end

  # POST /facilities/:facility_id/movable_transactions/move
  def move_transactions
    begin
      reassign_account_from_params!
      bulk_reassignment_success
    rescue ActiveRecord::RecordInvalid => reassignment_error
      bulk_reassignment_failure(reassignment_error)
    end
    redirect_to facility_movable_transactions_path
  end

  def get_movable_transactions(account)
    @order_details.find_all do |order_detail|
      order_detail.can_be_assigned_to_account?(account)
    end
  end

  private

  def facility_params
    params.require(:facility).permit(*self.class.permitted_facility_params)
  end

  def self.permitted_facility_params
    @@permitted_facility_params ||=
      %i(
        abbreviation
        accepts_multi_add
        address
        banner_notice
        description
        email
        fax_number
        is_active
        name
        order_notification_recipient
        phone_number
        short_description
        show_instrument_availability
        url_name
      )
  end

  def ensure_order_details_selected
    if @order_details.count < 1
      flash[:alert] = I18n.t("controllers.facilities.bulk_reassignment.no_transactions_selected")
      redirect_to facility_movable_transactions_path(params[:facility_id])
    end
  end

  def initialize_chart_string_reassignment_form
    @chart_string_reassignment_form = ChartStringReassignmentForm.new(@order_details)
    @date_range_field = "journal_or_statement_date"
  end

  def load_order_details
    @order_details = OrderDetail.where(id: params[:order_detail_ids])
  end

  def load_transactions
    @selected_account = Account.find(params[:chart_string_reassignment_form][:account_id])
    @movable_transactions = get_movable_transactions(@selected_account)
    @unmovable_transactions = @order_details - @movable_transactions
  end

  def bulk_reassignment_success
    flash[:notice] = I18n.t("controllers.facilities.bulk_reassignment.move.success",
                            count: @order_details.count)
  end

  def bulk_reassignment_failure(reassignment_error)
    flash[:alert] = I18n.t "controllers.facilities.bulk_reassignment.move.failure",
                           reassignment_error: reassignment_error,
                           order_detail_id: reassignment_error.record.id
  end

  def reassign_account_from_params!
    account = Account.find(params[:account_id])
    OrderDetail.reassign_account!(account, @order_details)
  end

  def set_admin_billing_tab
    @active_tab = "admin_billing"
  end

  def set_column_class
    @columns = ""
    @columns = "columns" if SettingsHelper.feature_on?(:product_list_columns)
  end

  def azlist_on?
    SettingsHelper.feature_on?(:azlist)
  end
  helper_method :azlist_on?

end
