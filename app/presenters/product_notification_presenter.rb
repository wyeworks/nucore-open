# frozen_string_literal: true

class ProductNotificationPresenter < SimpleDelegator
  def display_name
    "#{name} (#{users_count} Users)"
  end

  def product_names
    products.pluck(:name).join(", ") || "No products added"
  end
end
