# frozen_string_literal: true

module TransactionSearch
  class ProductSearcher < BaseSearcher
    def options
      # Uses a subquery, i.e. SELECT "PRODUCTS".* FROM "PRODUCTS"
      # WHERE "PRODUCTS"."ID" IN (SELECT distinct order_details.product_id FROM "ORDER_DETAILS" ...
      Product.where(id: order_details.distinct.select(:product_id)).order(:name)
    end

    def search(params)
      order_details.for_products(params).includes(:product)
    end

    def data_attrs(product)
      {
        facility: product.facility_id,
        restricted: product.requires_approval?,
        product_type: product.type.downcase,
      }
    end
  end
end
