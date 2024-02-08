# frozen_string_literal: true

class PricePolicyUpdater

  def self.update_all(product, price_policies, start_date, expire_date, params)
    new(product, price_policies, start_date, expire_date, params).update_all
  end

  def self.destroy_all_for_product!(product, start_date)
    price_policies = product.price_policies.for_date(start_date)
    raise ActiveRecord::RecordNotFound if price_policies.none?
    new(product, price_policies, start_date).destroy_all!
  end

  def initialize(product, price_policies, start_date, expire_date = nil, params = nil)
    @product = product
    @price_policies = price_policies
    @start_date = start_date
    @expire_date = expire_date
    @params = params
  end

  def destroy_all!
    ActiveRecord::Base.transaction do
      @price_policies.destroy_all || raise(ActiveRecord::Rollback)
    end
  end

  def update_all
    if @product.duration_pricing_mode?
      assign_attributes_for_stepped_billing && save
    else
      assign_attributes && save
    end
  end

  private

  def assign_attributes
    @price_policies.each do |price_policy|
      price_policy.assign_attributes(price_group_attributes(price_policy.price_group))
    end
  end

  def save
    ActiveRecord::Base.transaction do
      @price_policies.all?(&:save) || raise(ActiveRecord::Rollback)
    end
  end

  def assign_attributes_for_stepped_billing
    @price_policies.each do |price_policy|
      price_group_id = price_policy.price_group.id
      duration_rate_params = @params.dig("price_policy_#{price_group_id}", "duration_rates_attributes")

      if duration_rate_params.present?
        duration_rate_params.each do |key, dr|
          values_are_blank = dr["rate"].blank? && dr["subsidy"].blank?
          rate_exists = DurationRate.where(id: dr[:id]).present?
          duration_rate_params[key].merge! ({ _destroy: '1' }) if values_are_blank && rate_exists
        end
      end
    end

    @price_policies.each do |price_policy|
      price_policy.assign_attributes(price_group_attributes(price_policy.price_group))
    end
  end

  def price_group_attributes(price_group)
    permitted_price_group_attributes(price_group).merge(
      start_date: @start_date,
      expire_date: @expire_date,
    ).merge(permitted_common_params)
  end

  def permitted_price_group_attributes(price_group)
    price_policy_params = @params["price_policy_#{price_group.id}"]&.permit(*permitted_params)

    return { can_purchase: false } if price_policy_params.nil? || price_policy_params.keys.empty? || price_policy_params.keys == ["duration_rates_attributes"]

    price_policy_params
  end

  def permitted_common_params
    @params.permit(:charge_for, :note, :created_by_id)
  end

  def permitted_params
    [
      :can_purchase,
      :usage_rate,
      :usage_subsidy,
      :minimum_cost,
      :cancellation_cost,
      :unit_cost,
      :unit_subsidy,
      duration_rates_attributes: [
        :id,
        :subsidy,
        :rate,
        :price_policy_id,
        :min_duration_hours,
        :_destroy
      ]
    ].tap do |attributes|
      attributes << :full_price_cancellation if SettingsHelper.feature_on?(:charge_full_price_on_cancellation)
    end
  end

end
