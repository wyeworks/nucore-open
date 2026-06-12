# frozen_string_literal: true

class ProductNotificationPresenter < SimpleDelegator
  def display_line
    notification_type_human =
      ProductNotification
      .human_attribute_name("notification_type.#{notification_type}")

    [
      name,
      notification_type_human,
      "#{users_count} Users"
    ].compact_blank.join(" • ")
  end

  def product_names
    products.pluck(:name).join(", ") || "No products added"
  end
end
