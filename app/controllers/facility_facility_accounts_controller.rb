# frozen_string_literal: true

class FacilityFacilityAccountsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  load_and_authorize_resource class: FacilityAccount

  layout "two_column"

  cattr_accessor(:form_class) { ::FacilityAccountForm }

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /facilities/:facility_id/facility_accounts(.:format)
  def index
    @accounts = current_facility.facility_accounts
  end

  # GET /facilities/:facility_id/facility_accounts/new(.:format)
  def new
    @facility_account = form_class.new(
      current_facility.facility_accounts.new(is_active: true, revenue_account: Settings.accounts.revenue_account_default),
    )
  end

  # POST /facilities/:facility_id/facility_accounts(.:format)
  def create
    @facility_account = form_class.new(
      current_facility.facility_accounts.new(create_params),
    )
    @facility_account.created_by = session_user.id

    if @facility_account.save
      flash[:notice] = text("create.success", model: FacilityAccount.model_name.human)
      redirect_to facility_facility_accounts_path
    else
      render action: "new"
    end
  end

  # GET /facilities/:facility_id/facility_accounts/:id/edit(.:format)
  def edit
    @facility_account = current_facility.facility_accounts.find(params[:id])
  end

  # PUT /facilities/:facility_id/facility_accounts/:id(.:format)
  def update
    @facility_account = current_facility.facility_accounts.find(params[:id])

    if @facility_account.update_attributes(update_params)
      flash[:notice] = text("update.success", model: FacilityAccount.model_name.human)
      redirect_to facility_facility_accounts_path
    else
      render action: "edit"
    end
  end

  private

  def create_params
    params.require(:facility_account).permit(:revenue_account, :account_number, :is_active, account_number_parts: FacilityAccount.account_number_field_names)
  end

  def update_params
    params.require(:facility_account).permit(:is_active)
  end

end
