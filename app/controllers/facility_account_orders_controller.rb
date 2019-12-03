# frozen_string_literal: true

class FacilityAccountOrdersController < ApplicationController

  admin_tab :all

  before_action :authenticate_user!
  before_action { @active_tab = "admin_users" }

  layout "two_column"

  def index
    @account = Account.find(params[:account_id])
    authorize! :index, @account

    @order_details =
      @account
      .order_details
      .for_facility(current_facility)
      .purchased
      .order(ordered_at: :desc)
      .paginate(page: params[:page])
  end

end
