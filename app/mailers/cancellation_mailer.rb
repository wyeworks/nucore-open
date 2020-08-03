# frozen_string_literal: true

class CancellationMailer < ApplicationMailer

  def notify_facility(order_detail)
    @order_detail = order_detail
    @product = order_detail.product
    if @product.cancellation_email_recipients.any?
      mail(
        to: @product.cancellation_email_recipients,
        subject: text("views.cancellation_mailer.notify_facility.subject", facility: @order_detail.facility, order_detail: @order_detail),
      )
    end
  end

  private

  def interpolation_args
    {
      order_detail: @order_detail,
      order_detail_link: facility_order_url(@order_detail.facility, @order_detail.order),
      canceler: Users::NamePresenter.new(@order_detail.canceled_by_user, username_label: true).full_name,
      product: @product,
      times: @order_detail.reservation,
    }
  end
  helper_method :interpolation_args

end
