# frozen_string_literal: true

class EstimateBuilder
  include DateHelper

  attr_reader :facility, :current_user

  def initialize(facility, current_user)
    @facility = facility
    @current_user = current_user
  end

  def build_estimate(estimate_params)
    expires_at = parse_usa_date(estimate_params[:expires_at])
    estimate = @facility.estimates.new(estimate_params.merge({ created_by_id: current_user.id, expires_at: }).except(:estimate_details_attributes))

    estimate_params[:estimate_details_attributes].each_value do |detail_params|
      product = Product.find(detail_params[:product_id])

      next if product.blank?

      unless product.is_a?(Bundle)
        estimate.estimate_details.new(detail_params)
        next
      end

      product.bundle_products.each do |bundle_product|
        bundle_product_product = bundle_product.product
        attributes = detail_params.except(:product_id)
        attributes[:product] = bundle_product_product

        if bundle_product.quantity > 1
          attributes[:quantity] = bundle_product.quantity * attributes[:quantity].to_i
        end

        estimate.estimate_details.new(attributes)
      end
    end

    estimate.save

    estimate
  end
end
