# frozen_string_literal: true

module PriceGroupProductsHelper
  def can_purchase?(price_group)
    @price_group_products.any? { |pgp| pgp.price_group == price_group }
  end

  def reservation_window(price_group)
    @price_group_products.each { |pgp| return pgp.reservation_window if pgp.price_group == price_group }
    "" # return empty if it doesn't find one
  end
end
