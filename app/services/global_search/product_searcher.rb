# frozen_string_literal: true

module GlobalSearch

  class ProductSearcher < Base

    def template
      "products"
    end

    private

    def search
      Product.includes(:facility).full_text([:name, :description], query)
    end

    def restrict(products)
      facilities = user ? user.operable_facilities.pluck(:id) : []

      products.in_active_facility.not_archived.merge(Product.where(is_hidden: false).or(Product.where(facility: facilities)))
    end

  end

end
