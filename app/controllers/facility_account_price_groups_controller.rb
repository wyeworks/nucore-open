# frozen_string_literal: true

class FacilityAccountPriceGroupsController < ApplicationController
  admin_tab :all

  before_action :authenticate_user!
  before_action { @active_tab = "admin_users" }
  before_action :load_resources
  before_action :authorize_account

  layout "two_column"

  def show
  end

  def load_resources
    @account = Account.find(params[:account_id])
    @price_groups =
      @account
      .price_groups_relation
      .includes(:facility)
      .order(:global, :is_internal, :name)
  end

  def authorize_account
    authorize! :index, @account
  end
end
