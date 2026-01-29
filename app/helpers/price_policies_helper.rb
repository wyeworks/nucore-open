# frozen_string_literal: true

module PricePoliciesHelper

  def price_policy_path(price_policy_or_product, url_date)
    product = price_policy_or_product.respond_to?(:product) ? price_policy_or_product.product : price_policy_or_product
    [current_facility, product, :price_policy, id: url_date]
  end

  def price_policies_path
    [current_facility, @product, PricePolicy]
  end

  def charge_for_options(instrument)
    if instrument.reservation_only?
      [["Reservation", InstrumentPricePolicy::CHARGE_FOR[:reservation]]]
    else
      InstrumentPricePolicy::CHARGE_FOR.map { |k, v| [k.to_s.titleize, v] }
    end
  end

  def display_usage_rate(price_group, price_policy)
    param_for_price_group(price_group, :usage_rate) ||
      display_rate(base_hourly_usage_rate(price_group, price_policy))
  end

  def base_hourly_usage_rate(price_group, price_policy)
    if price_group.external_subsidy? && SettingsHelper.feature_on?(:external_price_group_subsidies)
      parent_policy = price_policy.product.price_policies
                                  .current
                                  .find_by(price_group: price_group.parent_price_group)
      parent_policy&.hourly_usage_rate
    else
      price_policy.hourly_usage_rate
    end
  end

  def display_usage_subsidy(price_group, price_policy)
    param_for_price_group(price_group, :usage_subsidy) ||
      display_rate(price_policy.hourly_usage_subsidy)
  end

  def display_rate(value)
    number_to_currency(value, unit: "", delimiter: "")
  end

  private

  def param_for_price_group(price_group, key)
    price_group_key = "price_policy_#{price_group.id}"
    params[price_group_key].present? && params[price_group_key][key]
  end

end
