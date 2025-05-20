# frozen_string_literal: true

class FacilityEstimatesController < ApplicationController
  include DateHelper

  admin_tab :all
  before_action { @active_tab = "admin_estimates" }
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  load_and_authorize_resource class: Estimate
  before_action :load_estimate, only: [:show, :recalculate]
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
    respond_to do |format|
      format.html
      format.csv do
        filename = "#{@estimate.facility.abbreviation}_estimate_#{@estimate.id}.csv"
        send_data Estimates::EstimateCsvService.new(@estimate).to_csv,
                  filename:,
                  type: "text/csv",
                  disposition: "attachment"
      end
    end
  end

  def search
    respond_to do |format|
      format.json do
        render json: @users
      end
    end
  end

  def new
    @estimate = current_facility.estimates.new(expires_at: 1.month.from_now)
    @estimate.estimate_details.build

    set_collections_for_select
  end

  def create
    expires_at = parse_usa_date(facility_estimate_params[:expires_at])
    @estimate = current_facility.estimates.new(facility_estimate_params.merge(created_by_id: current_user.id, expires_at:))

    if @estimate.save
      flash[:notice] = t(".success")
      redirect_to facility_estimate_path(current_facility, @estimate)
    else
      set_collections_for_select
      flash.now[:error] = t(".error")
      render action: :new
    end
  end

  def add_product_to_estimate
    product_id = params[:product_id]

    product = Product.find(product_id)

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

  def recalculate
    if @estimate.recalculate
      flash[:notice] = t(".success")
    else
      flash[:error] = t(".error")
    end

    redirect_to facility_estimate_path(current_facility, @estimate)
  end

  private

  def facility_estimate_params
    params.require(:estimate).permit(
      :name, :price_group_id, :user_id, :custom_name, :note, :expires_at,
      estimate_details_attributes: [:id, :product_id, :quantity, :duration, :duration_unit, :_destroy]
    )
  end

  def load_estimate
    @estimate = current_facility.estimates.includes(estimate_details: :product).find(params[:id])
  end

  def set_products
    @products = current_facility.products.available_for_estimates.alphabetized.map { |p| [p.name, p.id] }
  end

  def set_users
    search_term = params[:query]&.strip

    @users = if search_term.present?
               UserFinder.search(search_term, limit: 20, actives_only: true).map { |user| { id: user.id, name: "#{user.full_name} (#{user.username})" } }
             else
               []
             end
  end

  def set_price_groups
    @price_groups = current_facility.price_groups.map { |pg| [pg.name, pg.id] }
  end

  def set_collections_for_select
    set_products
    set_price_groups
  end
end
