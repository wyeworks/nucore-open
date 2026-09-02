# frozen_string_literal: true

class FacilityAccountsController < ApplicationController

  include AccountSuspendActions
  include SearchHelper
  include CsvEmailAction

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_account, except: :index
  before_action :build_account, only: [:new, :create]
  before_action :set_facility_accounts_for_user, only: [:accounts_available_for_order]
  before_action :set_account_types, only: :index

  authorize_resource :account, except: [:accounts_available_for_order]

  before_action { @active_tab = "admin_users" }
  layout "two_column"

  # GET /facilties/:facility_id/accounts
  def index
    searcher = AccountSearcher.new(
      filter_params[:search_term],
      scope: account_scope,
      filter_params:,
    )

    if searcher.valid?
      respond_to do |format|
        format.html do
          @accounts = searcher.results.includes(:owner_user)
          @accounts = @accounts.paginate(page: params[:page])
        end
        format.csv { export_accounts_csv }
      end
    else
      flash.now[:error] = "Search terms must be 3 or more characters."
    end
  end

  # GET /facilties/:facility_id/accounts/:id
  def show
  end

  # GET /facilities/:facility_id/accounts/new
  def new
  end

  # POST /facilities/:facility_id/accounts
  def create
    # The builder might add some errors to base. If those exist,
    # we don't want to try saving as that would clear the original errors
    if @account.errors[:base].empty? && @account.save
      LogEvent.log(@account, :create, current_user)
      flash[:notice] = I18n.t("controllers.facility_accounts.create.success")
      redirect_to facility_user_accounts_path(current_facility, @account.owner_user)
    else
      render action: "new"
    end
  end

  # GET /facilities/:facility_id/accounts/:id/edit
  def edit
  end

  # PUT /facilities/:facility_id/accounts/:id
  def update
    @account = AccountBuilder.for(@account.class).new(
      account: @account,
      current_user: current_user,
      owner_user: @owner_user,
      params: params,
    ).update

    if @account.save
      LogEvent.log(@account, :update, current_user)
      flash[:notice] = I18n.t("controllers.facility_accounts.update")
      redirect_to facility_account_path
    else
      render action: "edit"
    end
  end

  def new_account_user_search
  end

  # GET /facilities/:facility_id/accounts/:account_id/members
  def members
  end

  # GET /facilities/:facility_id/accounts/:account_id/statements
  def statements
    @statements = Statement.for_facility(current_facility)
                           .where(account: @account)
                           .paginate(page: params[:page])
  end

  # GET /facilities/:facility_id/accounts/:account_id/statements/:statement_id
  def show_statement
    @statement = Statement.for_facility(current_facility)
                          .where(account: @account)
                          .find(params[:statement_id])

    respond_to do |format|
      format.pdf do
        @statement_pdf = StatementPdfFactory.instance(@statement)
        render "statements/show"
      end
    end
  end

  def accounts_available_for_order
    respond_to do |format|
      format.json do
        render json: @facility_accounts_for_user
      end
    end
  end

  private

  def available_account_types
    @available_account_types ||= Account.config.account_types_for_facility(current_facility, :create).select do |account_type|
      current_ability.can?(:create, account_type.constantize)
    end
  end
  helper_method :available_account_types

  def current_account_type
    @current_account_type ||= if available_account_types.include?(params[:account_type])
                                params[:account_type]
                              else
                                available_account_types.first
                              end
  end
  helper_method :current_account_type

  def init_account
    if params.key? :id
      @account = Account.find params[:id].to_i
    elsif params.key? :account_id
      @account = Account.find params[:account_id].to_i
    end
  end

  def build_account
    raise CanCan::AccessDenied if current_account_type.blank?

    @owner_user = User.find(params[:owner_user_id])
    @account = AccountBuilder.for(current_account_type).new(
      account_type: current_account_type,
      facility: current_facility,
      current_user: current_user,
      owner_user: @owner_user,
      params: params,
    ).build
  end

  def set_facility_accounts_for_user
    order_id = params[:order_id]
    order = Order.find(order_id) if order_id

    if order
      order_user = order.user
      @facility_accounts_for_user = AvailableAccountsFinder.new(order_user, current_facility).accounts.map { |a| { id: a.id, label: a.to_s } }
    else
      @facility_accounts_for_user = []
    end
  end

  def set_account_types
    if SettingsHelper.feature_on?("accounts.account_tabs")
      @account_types = Account.config.account_types
    end
  end

  def export_accounts_csv
    queue_csv_report_email(
      Reports::AccountSearchReport,
      search_term: filter_params[:search_term],
      facility: SerializableFacility.new(current_facility),
      filter_params:,
    )
  end

  # Default scope is to show latest accounts used.
  #
  # If we are filtering then return all accounts for facility.
  def account_scope
    if filters_active?
      Account.for_facility(current_facility)
    else
      Account.with_orders_for_facility(current_facility)
    end
  end

  def filter_params
    @filter_params ||=
      params
      .permit(:search_term, :account_type, :suspended, :account_status)
      .to_h
      .symbolize_keys
      .compact_blank
      .reverse_merge(default_filters)
  end

  # Filter active if it's a form submission
  def filters_active?
    params[:commit].present?
  end

  helper_method :filters_active?

  def default_filters
    if SettingsHelper.feature_on?("accounts.account_tabs")
      { suspended: "false" }
    else
      { account_status: "active" }
    end
  end

end
