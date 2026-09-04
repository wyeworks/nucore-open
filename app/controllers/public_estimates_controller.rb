# frozen_string_literal: true

class PublicEstimatesController < ApplicationController

  skip_before_action :authenticate_user!

  def show
    @facilities = Facility.active.alphabetized
    @facility = @facilities.find_by(id: params[:facility_id])
    @products = @facility ? public_products : Product.none
    @price_group = PriceGroup.for_public_estimate(
      customer_type: params[:customer_type],
      profit_status: params[:profit_status],
    )
    @estimate = build_estimate if @price_group && requested_quantities.any?
    @total = @estimate.estimate_details.sum { |estimate_detail| estimate_detail.cost || 0 } if @estimate
  end

  private

  def public_products
    @facility.products.active.available_for_estimates.where.not(type: "Bundle").alphabetized
  end

  def requested_quantities
    @requested_quantities ||=
      params[:quantities].presence&.to_unsafe_h&.select { |_id, quantity| quantity.to_i.positive? } || {}
  end

  def build_estimate
    estimate = Estimate.new(facility: @facility, price_group: @price_group)

    requested_quantities.each do |product_id, quantity|
      product = @products.find_by(id: product_id)
      next if product.blank?

      estimate.estimate_details.build(
        product:,
        quantity: quantity.to_i,
        duration: params.dig(:durations, product_id).presence,
      )
    end

    estimate.estimate_details.each(&:assign_price_policy_and_cost)
    estimate
  end

end
