class CloneAccountMembershipsController < ApplicationController

  admin_tab :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action { authorize! :clone_accounts, current_facility }
  before_action :init_clone_to_user
  before_action :init_clone_from_user, only: [:new, :create]
  before_action { @active_tab = "accounts" }

  layout -> { request.xhr? ? false : "two_column" }

  def index
  end

  def search
    @users = UserFinder.search(params[:search_term])

    render :search
  end

  def new
  end

  def create
    cloner = AccountMembershipCloner.new(
      account_users_to_clone: @account_users.where(id: clone_account_membership_params[:account_user_ids]),
      clone_to_user: @clone_to_user,
      acting_user: current_user,
    )

    if cloner.perform
      flash[:notice] = text("success")

      redirect_to facility_user_accounts_path
    else
      flash[:error] = text(
        "error",
        account: cloner.error.record.account,
        message: cloner.error.message
      )

      redirect_to new_facility_user_clone_account_membership_path(user_to_clone_id: @clone_to_user.id)
    end
  end

  private

  def init_clone_from_user
    @clone_from_user = User.find(params[:user_to_clone_id])
    @account_users = AccountUser.active.where(user: @clone_from_user).joins(:account).merge(Account.for_facility(current_facility))
  end

  def init_clone_to_user
    @user = @clone_to_user = User.find(params[:user_id])
  end

  def clone_account_membership_params
    params.permit(:user_to_clone_id, account_user_ids: [])
  end

end
