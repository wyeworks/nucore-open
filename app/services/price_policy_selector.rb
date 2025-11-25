# frozen_string_literal: true

class PricePolicySelector

  def initialize(product, detail, date = Time.zone.now)
    @product = product
    @detail = detail
    @date = date
  end

  def cheapest_policy
    groups = @detail.price_groups
    return nil if groups.empty?

    # When feature flag is enabled, try account price groups first, then fallback to all groups
    if prioritize_account_price_groups?
      account_price_groups = @detail.account.account_price_groups

      if account_price_groups.present?
        policy = find_cheapest_for_groups(account_price_groups)
        return policy if policy
      end
    end

    find_cheapest_for_groups(groups)
  end

  private

  def prioritize_account_price_groups?
    @detail.is_a?(OrderDetail) &&
      @detail.account &&
      SettingsHelper.feature_on?(:user_based_price_groups_exclude_purchaser)
  end

  def find_cheapest_for_groups(groups)
    price_policies = current_price_policies_for_groups(groups)

    # provide a predictable ordering of price groups so that equal unit costs
    # are always handled the same way. Put the base group at the front of the
    # price policy array so that it takes precedence over all others that have
    # equal unit cost. See task #49823.
    base_ndx = price_policies.index { |pp| pp.price_group == PriceGroup.base }
    base = price_policies.delete_at base_ndx if base_ndx
    price_policies.sort! { |pp1, pp2| pp1.price_group.name <=> pp2.price_group.name }
    price_policies.unshift base if base

    cheapest_policy_from_list(price_policies)
  end

  def current_price_policies_for_groups(groups)
    @product.current_price_policies(@date).newest.to_a.delete_if do |pp|
      pp.restrict_purchase? || groups.exclude?(pp.price_group)
    end
  end

  def cheapest_policy_from_list(price_policies)
    if @detail.is_a?(OrderDetail)
      price_policies.min_by do |pp|
        # default to very large number if the estimate returns a nil
        costs = pp.estimate_cost_and_subsidy_from_order_detail(@detail) || { cost: 999_999_999, subsidy: 0 }
        costs[:cost] - costs[:subsidy]
      end
    elsif @detail.is_a?(EstimateDetail) && SettingsHelper.feature_on?(:show_estimates_option)
      price_policies.min_by do |pp|
        # default to very large number if the estimate returns a nil
        pp.estimate_cost_from_estimate_detail(@detail) || 999_999_999
      end
    end
  end

end
