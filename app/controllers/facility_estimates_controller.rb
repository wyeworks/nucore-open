# frozen_string_literal: true

class FacilityEstimatesController < ApplicationController
  include DateHelper

  admin_tab :all
  before_action { @active_tab = "admin_estimates" }
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  load_and_authorize_resource class: Estimate
  before_action :load_estimate, only: [:show]
  before_action :set_users, only: [:search]

  def index
  end

  def show
  end

  def search
    respond_to do |format|
      format.json do
        render json: @users
      end
    end
  end

  def new
    @estimate = current_facility.estimates.new
  end

  def create
    expires_at = parse_usa_date(facility_estimate_params[:expires_at])
    @estimate = current_facility.estimates.new(facility_estimate_params.merge(created_by_id: current_user.id, expires_at:))

    if @estimate.save
      flash[:notice] = t(".success")
      redirect_to facility_estimate_path(current_facility, @estimate)
    else
      render action: :new
    end
  end

  private

  def facility_estimate_params
    params.require(:estimate).permit([:name, :user_id, :note, :expires_at])
  end

  def load_estimate
    @estimate = current_facility.estimates.find(params[:id])
  end

  def set_users
    search_term = params[:query]&.strip

    if search_term.present?
      query = User.active.where("LOWER(users.last_name) LIKE :search OR LOWER(users.first_name) LIKE :search OR LOWER(users.username) LIKE :search", search: "%#{search_term.downcase}%")

      @users = query.sort_last_first.limit(20).map { |u| { id: u.id, name: u.full_name } }
    else
      @users = []
    end
  end
end
