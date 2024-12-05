# frozen_string_literal: true

class ProductsController < ApplicationController

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as, except: [:index]
  before_action :init_current_facility
  before_action :set_facility_products, only: [:available_for_cross_core_ordering]

  load_and_authorize_resource

  layout "two_column"

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /products
  def index
    if current_facility.instruments.first
      redirect_to facility_instruments_path
    elsif current_facility.services.first
      redirect_to facility_services_path
    elsif current_facility.items.first
      redirect_to facility_items_path
    else
      redirect_to facility_instruments_path
    end
  end

  def available_for_cross_core_ordering
    respond_to do |format|
      format.js do
        render json: @facility_products
      end
    end
  end

  def set_facility_products
    original_order_facility = params[:original_order_facility]&.to_i

    query = current_facility.products.mergeable_into_order
    adding_to_original_order = current_facility.id == original_order_facility
    query = query.cross_core_available unless adding_to_original_order

    @facility_products = query.alphabetized.map { |p| { id: p.id, name: p.name, time_based: p.order_quantity_as_time? } }
  end
end
