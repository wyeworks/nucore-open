# frozen_string_literal: true

module BelongsToProductController

  extend ActiveSupport::Concern

  included do
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :init_product
  end

  private

  def init_product
    @product = current_facility.products.find_by!(url_name: product_id)
  end

  def product_id
    params[product_key]
  end

  def product_key
    valid_ids = Product.types.map { |t| "#{t.model_name.param_key}_id" }
    params.keys.find { |k| k.in?(valid_ids) }
  end

end
