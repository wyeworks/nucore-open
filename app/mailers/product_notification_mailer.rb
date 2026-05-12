# frozen_string_literal: true

class ProductNotificationMailer < ApplicationMailer
  ##
  # A future time slot has become available
  def slot_available(product, user, start_time, end_time)
    @product = product
    @user = user
    @time_range = TimeRange.new(start_time, end_time)

    mail(
      to: user.email,
      subject: text(
        "product_notification_mailer.slot_available.subject",
        product_facility: "#{product} (#{product.facility.abbreviation})",
        time_range: @time_range,
      ),
    )
  end
end
