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
    if @product.is_a?(Instrument) && @product.duration_pricing_mode?
      save_for_stepped_billing
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
      duration_rates = @params["price_policy_#{price_group_id}"]["price_group_attributes"]["duration_rates_attributes"]
      duration_rates.values.each_with_index do |dr, index|
        if dr["rate"].present? || dr["subsidy"].present?
          rate_start_id = dr["rate_start_id"] || @product.rate_starts[index]&.id

          duration_rates["#{index}"].merge! ({ rate_start_id: rate_start_id, price_group_id: price_group_id })
        else
          duration_rates.delete(index.to_s)
        end
      end
    end

    @price_policies.each do |price_policy|
      price_policy.assign_attributes(price_group_attributes(price_policy.price_group))
    end
  end

  def save_for_stepped_billing
    ActiveRecord::Base.transaction do
      (save_product && assign_attributes_for_stepped_billing && @price_policies.all?(&:save)) || raise(ActiveRecord::Rollback)
    end
  end

  def save_product
    keys_from_built_rate_starts = []

    rate_starts_params = permitted_product_params[:rate_starts_attributes].clone
    rate_starts_params.values.each_with_index do |dr, index|
      if dr[:min_duration].blank?
        if dr[:id].present?
          rate_starts_params["#{index}"].merge! ({ _destroy: '1' })
        else
          keys_from_built_rate_starts << "#{index}"
        end
      end
    end

    @product.update({ rate_starts_attributes: rate_starts_params.except(*keys_from_built_rate_starts) })
  end

  def price_group_attributes(price_group)
    permitted_price_group_attributes(price_group).merge(
      start_date: @start_date,
      expire_date: @expire_date,
    ).merge(permitted_common_params)
  end

  def permitted_price_group_attributes(price_group)
    @params["price_policy_#{price_group.id}"]&.permit(*permitted_params) || { can_purchase: false }
  end

  def permitted_common_params
    @params.permit(:charge_for, :note, :created_by_id)
  end

  def permitted_product_params
    @params[:product].permit(rate_starts_attributes: [:min_duration, :id])
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
      price_group_attributes: [
        :id,
        duration_rates_attributes: [
          :id,
          :subsidy,
          :rate,
          :price_group_id,
          :rate_start_id
        ]
      ]
    ].tap do |attributes|
      attributes << :full_price_cancellation if SettingsHelper.feature_on?(:charge_full_price_on_cancellation)
    end
  end

end
