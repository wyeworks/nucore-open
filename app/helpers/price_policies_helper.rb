module PricePoliciesHelper


  def format_date(date)
    return date.is_a?(String) ? date : date.strftime("%m/%d/%Y")
  end

  def new_price_policy_path(product)
    send(:"new_facility_#{product.class.name.downcase}_price_policy_path")
  end

  def edit_price_policy_path(price_policy, url_date)
    product = price_policy.product
    send :"edit_facility_#{product.class.name.downcase}_price_policy_path", current_facility, product, url_date
  end

  def price_policy_path(price_policy_or_product, url_date)
    product = price_policy_or_product.respond_to?(:product) ? price_policy_or_product.product : price_policy_or_product
    send :"facility_#{product.class.name.downcase}_price_policy_path", current_facility, product, url_date
  end

  def price_policies_path
    send :"facility_#{@product.class.name.downcase}_price_policies_path"
  end

  def charge_for_options(instrument)
    if instrument.reservation_only?
      [ [ 'Reservation', InstrumentPricePolicy::CHARGE_FOR[:reservation] ] ]
    else
      InstrumentPricePolicy::CHARGE_FOR.map{|k, v| [ k.to_s.titleize, v ] }
    end
  end

  def usage_rate_from_params(price_group, price_policy)
    if params["price_policy_#{price_group.id}"].present?
      params["price_policy_#{price_group.id}"][:usage_rate] * 60
    elsif price_policy.hourly_usage_rate.present?
      price_policy.hourly_usage_rate
    else
      price_group.master_usage_rate * 60
    end
  end

  def display_usage_rate(price_group, price_policy)
    number_to_currency(usage_rate_from_params(price_group, price_policy),
      unit: '',
      delimiter: ''
    )
  end

  def display_usage_subsidy(price_group, price_policy)
    if params["price_policy_#{price_group.id}"].present?
      sub = params["price_policy_#{price_group.id}"][:usage_subsidy] * 60
    else
      sub = price_policy.hourly_usage_subsidy
    end

    number_to_currency sub, :unit => '', :delimiter => ''
  end
end
