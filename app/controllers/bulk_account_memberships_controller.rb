# frozen_string_literal: true

class BulkAccountMembershipsController < ApplicationController
  MAX_RESULTS = 200

  admin_tab :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :check_feature_enabled
  before_action :require_cross_facility
  before_action { authorize! :bulk_add_account_memberships, current_facility }
  before_action :init_user
  before_action { @active_tab = "admin_users" }

  layout "two_column"

  def index
    @search_term = params[:search_term].to_s.strip
    return if @search_term.blank?

    searcher = AccountSearcher.new(@search_term, scope: Account.for_facility(current_facility))

    if searcher.valid?
      accounts = searcher.results.includes(:owner_user).limit(MAX_RESULTS + 1).to_a
      @too_many_results = accounts.size > MAX_RESULTS
      @accounts = accounts.first(MAX_RESULTS)
      @current_memberships = @user.account_users.active.index_by(&:account_id)
    else
      flash.now[:error] = text("search_too_short", minimum: AccountSearcher::MINIMUM_SEARCH_LENGTH)
    end
  end

  def create
    accounts = Account.for_facility(current_facility).where(id: params[:account_ids]).includes(:account_users).order(:account_number)

    if accounts.empty?
      flash[:error] = text("none_selected")
      return redirect_to facility_user_bulk_account_memberships_path(current_facility, @user)
    end

    creator = BulkAccountMembershipCreator.new(accounts:, user: @user, acting_user: current_user)

    if creator.perform
      flash[:notice] = text("success", user: @user.full_name, count: creator.account_users.size)
      redirect_to facility_user_accounts_path(current_facility, @user)
    else
      flash[:error] = text("error", account: creator.error.record.account, message: creator.error.message)
      redirect_to facility_user_bulk_account_memberships_path(current_facility, @user)
    end
  end

  private

  def check_feature_enabled
    raise ActionController::RoutingError, "Bulk add business administrator is not enabled" unless SettingsHelper.feature_on?("accounts.bulk_add_business_administrator")
  end

  def require_cross_facility
    raise ActiveRecord::RecordNotFound unless current_facility.cross_facility?
  end

  def init_user
    @user = User.find(params[:user_id])
  end
end
