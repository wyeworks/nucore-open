# frozen_string_literal: true

class PricePolicyBuilder

  attr_reader :product, :start_date

  delegate :facility, to: :product

  def self.get(product, start_date)
    new(product, start_date).price_policies
  end

  def self.get_new_policies_based_on_most_recent(product, start_date)
    new(product, start_date).new_policies_based_on_most_recent
  end

  def initialize(product, start_date)
    @product = product
    @start_date = start_date
  end

  def price_policies
    @price_policies ||= get_price_policies
  end

  def new_policies_based_on_most_recent
    new_price_policies = price_policies.map do |price_policy|
      policy = last_price_policy_for_price_group(price_policy.price_group) || price_policy
      policy.start_date = start_date
      policy.expire_date = expire_date
      policy
    end
    return new_price_policies if price_policies != new_price_policies
    make_all_price_policies_purchaseable

    price_policies
  end

  private

  def editable?
    original_price_policies.empty? || original_price_policies_editable?
  end

  def get_price_policies
    return [] unless editable?
    facility.price_groups.map do |price_group|
      policy_for_price_group(price_group)
    end
  end

  def groups_with_policy
    @groups_with_policy ||= original_price_policies_hash
  end

  def last_price_policy_for_price_group(price_group)
    product
      .price_policies
      .where(price_group_id: price_group.id)
      .order(:expire_date)
      .last
  end

  def make_all_price_policies_purchaseable
    price_policies.each { |price_policy| price_policy.can_purchase = true }
  end

  def expire_date
    @expire_date ||= PricePolicy.generate_expire_date(start_date)
  end

  def model_class
    @model_class ||= "#{product.class}PricePolicy".constantize
  end

  def new_price_policy(price_group)
    model_class.new(
      price_group_id: price_group.id,
      product_id: product.id,
      can_purchase: false,
    )
  end

  def original_price_policies_hash
    original_price_policies.map do |price_policy|
      [price_policy.price_group, price_policy]
    end.to_h
  end

  def original_price_policies_editable?
    original_price_policies.all?(&:editable?)
  end

  def original_price_policies
    @original_price_policies ||= price_policies_for_start_date || []
  end

  def policy_for_price_group(price_group)
    groups_with_policy[price_group] || new_price_policy(price_group)
  end

  def price_policies_for_start_date
    return [] if start_date.blank?
    product.price_policies.for_date(start_date)
  end

end
