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
      number_to_currency(price_policy.hourly_usage_rate, unit: "", delimiter: "")
  end

  def display_usage_subsidy(price_group, price_policy)
    param_for_price_group(price_group, :usage_subsidy) ||
      number_to_currency(price_policy.hourly_usage_subsidy, unit: "", delimiter: "")
  end

  private

  def param_for_price_group(price_group, key)
    price_group_key = "price_policy_#{price_group.id}"
    params[price_group_key].present? && params[price_group_key][key]
  end

end
