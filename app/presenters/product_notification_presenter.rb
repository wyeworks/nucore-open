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
    ].compact.join(" • ")
  end

  def product_names
    products.pluck(:name).join(", ").presence || I18n.t("facility_product_notifications.show.empty_products")
  end
end
