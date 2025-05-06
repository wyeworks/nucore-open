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
    @estimates = current_facility.estimates
                                 .includes(:user)
                                 .order(created_at: :desc)

    @estimates = @estimates.where(user_id: params[:user_id]) if params[:user_id].present?

    @estimates = @estimates.where(expires_at: Time.current..) if params[:hide_expired] == "1"

    if params[:search].present?
      search_query = params[:search].strip
      @estimates = @estimates.where("LOWER(name) LIKE ?", "%#{search_query.downcase}%")

      @estimates = @estimates.or(Estimate.where(id: search_query)) if search_query.match?(/^\d+$/)
    end
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
    @estimate.estimate_details.build

    set_products
  end

  def create
    expires_at = parse_usa_date(facility_estimate_params[:expires_at])
    @estimate = current_facility.estimates.new(facility_estimate_params.merge(created_by_id: current_user.id, expires_at:))

    if @estimate.save
      flash[:notice] = t(".success")
      redirect_to facility_estimate_path(current_facility, @estimate)
    else
      set_products
      flash.now[:error] = t(".error")
      render action: :new
    end
  end

  def add_product_to_estimate
    product_id = params[:product_id]

    product = current_facility.products.find(product_id)

    @estimate_detail_products = if product.is_a?(Bundle)
                                  product.products
                                elsif product.present?
                                  [product]
                                else
                                  []
                                end

    respond_to do |format|
      format.js
    end
  end

  private

  def facility_estimate_params
    params.require(:estimate).permit(
      :name, :user_id, :note, :expires_at,
      estimate_details_attributes: [:id, :product_id, :quantity, :duration, :duration_unit, :_destroy]
    )
  end

  def load_estimate
    @estimate = current_facility.estimates.includes(estimate_details: :product).find(params[:id])
  end

  def set_products
    @products = current_facility.products.where({ type: %w[Item Service Instrument TimedService Bundle] }).not_archived.alphabetized.filter_map do |p|
      [p.name, p.id, { "data-time-unit" => p.time_unit }]
    end
  end

  def set_users
    search_term = params[:query]&.strip

    @users = if search_term.present?
               UserFinder.search(search_term, limit: 20, actives_only: true).map { |user| { id: user.id, name: "#{user.full_name} (#{user.username})" } }
             else
               []
             end
  end
end
