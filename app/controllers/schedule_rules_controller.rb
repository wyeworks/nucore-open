# frozen_string_literal: true

class ScheduleRulesController < ApplicationController

  include BelongsToProductController

  before_action :init_schedule_rule, only: [:edit, :update, :destroy]
  authorize_resource

  admin_tab :all
  layout "two_column"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # GET /facilities/alias/instruments/3/schedule_rules
  # GET /facilities/alias/instruments/3/schedule_rules.js?_=1279582221312&start=369205200&end=369810000
  def index
    @start_at       = Time.zone.at(params[:start].to_i)
    @end_at         = Time.zone.at(params[:end].to_i)
    @schedule_rules = @product.schedule_rules

    respond_to do |format|
      format.html # index.html.haml
      format.js do
        render json: ScheduleRules::CalendarPresenter.events(@schedule_rules).to_json
      end
    end
  end

  # GET /schedule_rules/new
  def new
    @schedule_rule = build_schedule_rule

    PriceGroup.by_display_order.globals.each do |price_group|
      @schedule_rule.price_group_discounts.build(price_group:, discount_percent: 0)
    end
    partition_price_group_discounts
  end

  # POST /schedule_rules
  def create
    @schedule_rule = @product.schedule_rules.new(schedule_rule_params)

    if @schedule_rule.save
      flash[:notice] = text("create")
      redirect_to action: :index
    else
      render action: "new"
    end
  end

  # GET /schedule_rules/1/edit
  def edit
    partition_price_group_discounts
  end

  # PUT /schedule_rules/1
  def update
    # if there are no boxes checked, the empty array will mark the
    # existing ones for destruction
    params[:schedule_rule][:product_access_group_ids] ||= []

    if @schedule_rule.update(schedule_rule_params)
      flash[:notice] = text("update")
      redirect_to action: :index
    else
      render action: "edit"
    end
  end

  # DELETE /schedule_rules/1
  def destroy
    @schedule_rule.destroy

    flash[:notice] = text("destroy")
    redirect_to action: :index
  end

  private

  def schedule_rule_params
    params
      .require(:schedule_rule)
      .permit(
        :start_hour, :start_min, :end_hour, :end_min,
        :on_sun, :on_mon, :on_tue, :on_wed, :on_thu, :on_fri, :on_sat,
        price_group_discounts_attributes: [:discount_percent, :price_group_id, :id],
        product_access_group_ids: []
      ).tap do |schedule_rule_params|
        if @product.start_time_disabled?
          schedule_rule_params.merge! ScheduleRule.full_day_attributes
        end
      end
  end

  def init_schedule_rule
    @schedule_rule = @product.schedule_rules.find(params[:id])
  end

  def partition_price_group_discounts
    @highlighted_price_group_discounts, @non_highlighted_price_group_discounts = @schedule_rule.price_group_discounts.partition do |pgd|
      pgd.price_group.highlighted
    end
    @highlighted_price_group_discounts = @highlighted_price_group_discounts.sort_by { |pgd| pgd.price_group.display_order }
    @non_highlighted_price_group_discounts = @non_highlighted_price_group_discounts.sort_by { |pgd| pgd.price_group.display_order }
  end

  def build_schedule_rule
    attrs = if @product.start_time_disabled?
              ScheduleRule.full_day_attributes
            else
              {
                start_hour: 9, start_min: 0,
                end_hour: 17, end_min: 0
              }
            end

    @product.schedule_rules.build(attrs)
  end

end
