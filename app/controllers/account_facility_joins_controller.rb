# frozen_string_literal: true

class AccountFacilityJoinsController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_account
  authorize_resource # Only global admins should have access

  layout "two_column"

  def edit
  end

  def update
    update_params = params.require(:account_facility_joins_form).permit(facility_ids: [])
    @account_facility_joins_form.assign_attributes(update_params)
    if @account_facility_joins_form.save
      redirect_to({ action: :edit }, notice: text("update.success"))
    else
      flash.now[:error] = text("update.error")
      render :edit
    end
  end

  private

  def init_account
    @account = Account.for_facility(current_facility).per_facility.find(params[:account_id])
    @account_facility_joins_form = AccountFacilityJoinsForm.new(account: @account, current_facility: current_facility)
  end

end
