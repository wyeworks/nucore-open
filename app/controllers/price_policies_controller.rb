# frozen_string_literal: true

class PricePoliciesController < ApplicationController

  include DateHelper

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product
  before_action :init_price_policy, except: [:index, :new]
  before_action :build_price_policies, only: [:create, :edit, :update]
  before_action :set_max_expire_date, only: [:new, :edit, :update]

  load_and_authorize_resource instance_name: :price_policy

  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /facilities/:facility_id/{product_type}/:product_id/price_policies
  def index
    @current_price_policies = @product.price_policies.current_and_newest
    @current_start_date = @current_price_policies.first.try(:start_date)
    @past_price_policies_by_date = @product.past_price_policies_grouped_by_start_date
    @next_price_policies_by_date = @product.upcoming_price_policies_grouped_by_start_date

    init_min_durations_for_index

    render "price_policies/index"
  end

  # GET /facilities/:facility_id/{product_type}/:product_id/price_policies/new
  def new
    @start_date = active_policies? ? Date.tomorrow : Date.today

    @price_policies = PricePolicyBuilder.get_new_policies_based_on_most_recent(
      @product,
      @start_date,
      force_new_policies = @product.duration_pricing_mode?
    )

    raise ActiveRecord::RecordNotFound if @price_policies.blank?

    build_instrument_stepped_billing_fields
  end

  # POST /facilities/:facility_id/{product_type}/:product_id/price_policies
  def create
    if update_policies_from_params
      redirect_to facility_product_price_policies_path, notice: text("create.success")
    else
      build_instrument_stepped_billing_fields

      flash.now[:error] = text("errors.save")

      render :new
    end
  end

  # PUT /facilities/:facility_id/{product_type}/:product_id/price_policies/:id
  def update
    if update_policies_from_params
      redirect_to facility_product_price_policies_path, notice: text("update.success")
    else
      build_instrument_stepped_billing_fields

      flash.now[:error] = text("errors.save")

      render :edit
    end
  end

  # GET /facilities/:facility_id/{product_type}/:product_id/price_policies/:id/edit
  def edit
    raise ActiveRecord::RecordNotFound if @price_policies.blank?

    build_instrument_stepped_billing_fields
  end

  # DELETE /facilities/:facility_id/{product_type}/:product_id/price_policies/:id
  def destroy
    return flash_remove_active_policy_warning_and_redirect if @start_date <= Date.today

    if PricePolicyUpdater.destroy_all_for_product!(@product, @start_date)
      flash[:notice] = text("destroy.success")
    else
      flash[:error] = text("destroy.failure")
    end
    redirect_to facility_product_price_policies_path
  end

  def translation_scope
    "controllers.price_policies"
  end

  private

  def active_policies?
    @product.price_policies.current.any?
  end

  def build_price_policies
    @price_policies ||= PricePolicyBuilder.get(@product, @start_date)
  end

  def facility_product_price_policies_path
    [current_facility, @product, PricePolicy]
  end

  # Override CanCan's find -- it won't properly search by zoned date
  def init_price_policy
    @start_date = parse_usa_date(params[:id] || params[:start_date])

    @price_policy = @product
                    .price_policies
                    .for_date(@start_date)
                    .first
  end

  def init_product
    id_param = params.except(:facility_id).keys.detect { |k| k.end_with?("_id") }
    class_name = id_param.sub(/_id\z/, "").camelize
    @product = current_facility.products
                               .of_type(class_name)
                               .find_by!(url_name: params[id_param])
  end

  def flash_remove_active_policy_warning_and_redirect
    flash[:error] =
      text("errors.remove_active_policy")
    redirect_to facility_product_price_policies_path
  end

  def set_max_expire_date
    @max_expire_date = PricePolicy.generate_expire_date(@start_date)
  end

  def update_policies_from_params
    PricePolicyUpdater.update_all(
      @product,
      @price_policies,
      parse_usa_date(params[:start_date])&.beginning_of_day,
      parse_usa_date(params[:expire_date])&.end_of_day,
      params.merge(created_by_id: current_user.id),
    )
  end

  # TO DO: consider moving the methods below to InstrumentPricePolicyController
  ## Duration Rates methods start here
  ## These only apply to instruments with duration pricing mode

  # Builds a collection of unique min duration hrs values
  # from price policies in memory,
  # adding nil values as needed to reach a total of MAX_RATE_STARTS (3),
  # in ascending order with nil values at the end.
  # Used to prefill values in the form.
  def build_min_durations
    min_durations = @price_policies.flat_map { |pp| pp.duration_rates.map(&:min_duration_hours) }.uniq
    (PricePolicy::MAX_RATE_STARTS - min_durations.length).times { min_durations << nil }
    @min_durations = min_durations.sort_by { |d| d || 1_000 }
  end

  # Builds a collection of unique min duration hrs values
  # for the current set of price policies,
  # adding nil values as needed to reach a total of MAX_RATE_STARTS (3),
  # in ascending order with nil values at the end.
  # Used to build the column sub-headers in the price policy table.
  def init_min_durations_for_index
    return unless @product.duration_pricing_mode?

    min_durations = @current_price_policies.flat_map { |pp| pp.duration_rates.map(&:min_duration_hours) }.uniq
    (PricePolicy::MAX_RATE_STARTS - min_durations.length).times { min_durations << nil }
    @min_durations = min_durations.sort_by { |d| d || 1_000 }
  end

  def build_duration_rates
    @price_policies.each do |price_policy|
      (PricePolicy::MAX_RATE_STARTS - price_policy.duration_rates.length).times { price_policy.duration_rates.build }
    end
  end

  def build_instrument_stepped_billing_fields
    if @product.duration_pricing_mode?
      build_min_durations
      build_duration_rates
    end
  end

end
