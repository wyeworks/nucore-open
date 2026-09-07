# frozen_string_literal: true

class PublicEstimatesController < ApplicationController

  skip_before_action :authenticate_user!

  def show
    @facilities = Facility.active.alphabetized
    @facility = @facilities.find_by(id: params[:facility_id])
    @customer_type_options = customer_type_options
    @price_group = PriceGroup.for_public_estimate(customer_type)
    @products = @facility ? priced_products : Product.none
    @estimate = build_estimate if @price_group && requested_quantities.any?
    @total = @estimate.estimate_details.sum { |estimate_detail| estimate_detail.cost || 0 } if @estimate
  end

  private

  def customer_types
    Settings.public_estimates.customer_types.map(&:to_s)
  end

  def customer_type
    customer_types.include?(params[:customer_type]) ? params[:customer_type] : customer_types.first
  end

  def customer_type_options
    customer_types.map { |key| [t(".customer_types.#{key}"), key] }
  end

  def priced_products
    return Product.none if @price_group.blank?

    facility_products.where(
      id: PricePolicy.current_for_date(Time.current).purchaseable
                     .where(price_group: @price_group).select(:product_id),
    )
  end

  def facility_products
    @facility.products.active.available_for_estimates.where.not(type: "Bundle").alphabetized
  end

  def requested_quantities
    @requested_quantities ||= permitted_product_values(:quantities).select { |_id, quantity| quantity.to_i.positive? }
  end

  def requested_durations
    @requested_durations ||= permitted_product_values(:durations)
  end

  def permitted_product_values(key)
    values = params[key]
    return {} unless values.is_a?(ActionController::Parameters)

    values.permit(@products.map { |product| product.id.to_s }).to_h
  end

  def build_estimate
    estimate = Estimate.new(facility: @facility, price_group: @price_group)

    products = @products.where(id: requested_quantities.keys).index_by { |product| product.id.to_s }

    requested_quantities.each do |product_id, quantity|
      product = products[product_id]
      next if product.blank?

      estimate.estimate_details.build(
        product:,
        quantity: quantity.to_i,
        duration: requested_durations[product_id].presence,
        duration_unit: product.time_unit,
      )
    end

    estimate.estimate_details.each(&:assign_price_policy_and_cost)
    estimate
  end

end
