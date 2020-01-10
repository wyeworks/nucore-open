# frozen_string_literal: true

class AccountUsersController < ApplicationController

  customer_tab  :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_account

  load_and_authorize_resource

  def initialize
    @active_tab = "accounts"
    super
  end

  # GET /accounts/:account_id/account_users/user_search
  def user_search
  end

  # GET /accounts/:account_id/account_users/new
  def new
    @user         = User.find(params[:user_id])
    @account_user = AccountUser.new
  end

  # POST /accounts/:account_id/account_users
  def create
    ## TODO add security
    @user = User.find(params[:user_id])
    @account_user = AccountUser.grant(@user, create_params[:user_role], @account, by: session_user)

    if @account_user.persisted?
      LogEvent.log(@account_user, :create, current_user)
      flash[:notice] = text("create.success", user: @user.full_name, account_type: @account.type_string)
      redirect_to account_account_users_path(@account)
    else
      flash.now[:error] = text("create.error", user: @user.full_name, account_type: @account.type_string)
      render :new
    end
  end

  # DELETE /accounts/:account_id/account_users/:id
  def destroy
    ## TODO add security

    @account_user.deleted_by = session_user.id
    if @account_user.destroy
      LogEvent.log(@account_user, :delete, current_user)
      flash[:notice] = text("destroy.success")
    else
      flash[:error] = text("destroy.error")
    end
    redirect_to account_account_users_path(@account)
  end

  protected

  def create_params
    params.require(:account_user).permit(:user_role)
  end

  def init_account
    @account = session_user.accounts.find(params[:account_id])
  end

  private

  def ability_resource
    @account
  end

end
