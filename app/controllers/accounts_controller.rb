# frozen_string_literal: true

class AccountsController < ApplicationController

  customer_tab  :all
  before_action :check_acting_as
  before_action :init_account, only: [:show, :user_search, :suspend, :unsuspend]

  include AccountSuspendActions

  load_and_authorize_resource only: [:show, :user_search, :suspend, :unsuspend]

  def initialize
    @active_tab = "accounts"
    super
  end

  # GET /accounts
  def index
    @account_users = session_user.account_users
    @administered_order_details_in_review = current_user.administered_order_details.in_review
  end

  # GET /accounts/1
  def show
  end

  # GET /accounts/1/user_search
  def user_search
    render(template: "account_users/user_search")
  end

  protected

  def init_account
    @account = Account.find(params[:id] || params[:account_id])
  end

  private

  def ability_resource
    @account
  end

end
