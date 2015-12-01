class FacilityAccountsController < ApplicationController
  module Overridable
    extend ActiveSupport::Concern

    module ClassMethods
      def billing_access_checked_actions
        [ :accounts_receivable, :show_statement ]
      end
    end

    def account_class_params
      params[:account] || params[:nufs_account]
    end

    def configure_new_account(account)
      # set temporary expiration to be updated later
      account.valid? # populate virtual charstring attributes required by set_expires_at
      account.errors.clear

      # be verbose with failures. Too many tasks (#29563, #31873) need it
      begin
        account.set_expires_at!
        account.errors.add(:base, I18n.t('controllers.facility_accounts.create.expires_at_missing')) unless account.expires_at
      rescue AccountNumberFormatError => e
        account.expires_at = Time.zone.now # Prevent expires_at missing message
      rescue ValidatorError => e
        account.errors.add(:base, e.message)
      end
    end
  end

  include Overridable
  include AccountSuspendActions
  include SearchHelper

  admin_tab     :all
  before_filter :authenticate_user!
  before_filter :check_acting_as
  before_filter :init_current_facility
  before_filter :init_account

  authorize_resource :class => Account

  before_filter :check_billing_access, :only => billing_access_checked_actions

  layout 'two_column'

  def initialize
    @active_tab =
      if SettingsHelper.feature_on?(:manage_payment_sources_with_users)
        "admin_users"
      else
        "admin_billing"
      end
    super
  end

  # GET /facilties/:facility_id/accounts
  def index
    accounts = Account.with_orders_for_facility(current_facility)
    accounts = accounts.where(facility_id: nil) if current_facility.cross_facility?

    @accounts = accounts.paginate(page: params[:page])
  end

  # GET /facilties/:facility_id/accounts/:id
  def show
  end

  # GET /facilities/:facility_id/accounts/new
  def new
    @owner_user = User.find(params[:owner_user_id])
    @account    = @owner_user.accounts.new(:expires_at => Time.zone.now + 1.year)
  end

  # GET /facilities/:facility_id/accounts/:id/edit
  def edit
  end

  # PUT /facilities/:facility_id/accounts/:id
  def update
    class_params = account_class_params

    if @account.is_a?(AffiliateAccount)
      class_params[:affiliate_other] = nil if class_params[:affiliate_id] != Affiliate.OTHER.id.to_s
    end

    if @account.update_attributes(class_params)
      flash[:notice] = I18n.t('controllers.facility_accounts.update')
      redirect_to facility_account_path
    else
      render :action => "edit"
    end
  end

  # POST /facilities/:facility_id/accounts
  def create
    builder = Accounts::AccountBuilder.new(current_facility, session_user, params)
    @account = builder.account
    @owner_user = User.find(params[:owner_user_id])
    configure_new_account @account
    return render :action => 'new' unless @account.errors[:base].empty?

    if @account.save
      flash[:notice] = 'Account was successfully created.'
      redirect_to facility_user_accounts_path(current_facility, @account.owner_user)
    else
      render :action => 'new'
    end
  end

  def new_account_user_search
  end

  def user_search
  end

  # GET /facilities/:facility_id/accounts/search
  def search
    flash.now[:notice] = 'This page is not yet implemented'
  end

  # GET/POST /facilities/:facility_id/accounts/search_results
  def search_results
    owner_where_clause =<<-end_of_where
      (
        LOWER(users.first_name) LIKE :term
        OR LOWER(users.last_name) LIKE :term
        OR LOWER(users.username) LIKE :term
        OR LOWER(CONCAT(users.first_name, users.last_name)) LIKE :term
      )
      AND account_users.user_role = :acceptable_role
      AND account_users.deleted_at IS NULL
    end_of_where
    term   = generate_multipart_like_search_term(params[:search_term])
    if params[:search_term].length >= 3

      # retrieve accounts matched on user for this facility
      @accounts = Account.joins(:account_users => :user).for_facility(current_facility).where(
        owner_where_clause,
        :term             => term,
        :acceptable_role  => 'Owner').
        order('users.last_name, users.first_name')

      # retrieve accounts matched on account_number for this facility
      @accounts += Account.for_facility(current_facility).where(
        "LOWER(account_number) LIKE ?", term).
        order('type, account_number')

      # only show an account once.
      @accounts = @accounts.uniq.paginate(:page => params[:page]) #hash options and defaults - :page (1), :per_page (30), :total_entries (arr.length)
    else
      flash.now[:errors] = 'Search terms must be 3 or more characters.'
    end
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def user_accounts
    @user = User.find(params[:user_id])
  end


  # GET /facilities/:facility_id/accounts/:account_id/members
  def members
  end

  # GET /facilities/:facility_id/accounts_receivable
  def accounts_receivable
    @account_balances = {}
    order_details = OrderDetail.for_facility(current_facility).complete
    order_details.each do |od|
      @account_balances[od.account_id] = @account_balances[od.account_id].to_f + od.total.to_f
    end
    @accounts = Account.find(@account_balances.keys)
  end

  # GET /facilities/:facility_id/accounts/:account_id/statements/:statement_id
  def show_statement
    @facility = current_facility

    if params[:statement_id] == "list"
      action = "show_statement_list"
      @statements =
        current_facility
        .statements
        .where(account_id: @account.id)
        .paginate(page: params[:page])
    else
      action = "show_statement"
      @statement = Statement.find(params[:statement_id])
      @order_details = @statement.order_details.paginate(page: params[:page])
    end

    respond_to do |format|
      format.html { render action: action }
      format.pdf { render_statement_pdf }
    end
  end

  private

  def render_statement_pdf
    @statement_pdf = StatementPdfFactory.instance(@statement, params[:show].blank?)
    render template: '/statements/show'
  end

  def init_account
    if params.has_key? :id
      @account=Account.find params[:id].to_i
    elsif params.has_key? :account_id
      @account=Account.find params[:account_id].to_i
    end
  end

end
