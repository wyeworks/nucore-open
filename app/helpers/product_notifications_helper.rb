# frozen_string_literal: true

module ProductNotificationsHelper
  def recipient_source_options
    ProductNotification.recipient_sources.keys.map do |key|
      [ProductNotification.human_attribute_name("recipient_source.#{key}"), key]
    end
  end
end
