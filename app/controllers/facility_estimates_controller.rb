# frozen_string_literal: true

class FacilityEstimatesController < ApplicationController
  include DateHelper

  admin_tab :all
  before_action { @active_tab = "admin_estimates" }
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  load_and_authorize_resource class: Estimate

  def index
  end

  def new
    @estimate = current_facility.estimates.new
  end

  def create
    expires_at = parse_usa_date(facility_estimate_params[:expires_at])
    @estimate = current_facility.estimates.new(facility_estimate_params.merge(created_by_id: current_user.id, expires_at:))

    if @estimate.save
      flash[:notice] = t(".success")
    else
      render action: :new
    end
  end

  private

  def facility_estimate_params
    params.require(:estimate).permit([:name, :user_id, :note, :expires_at])
  end
end
