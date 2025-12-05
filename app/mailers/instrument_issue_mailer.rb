# frozen_string_literal: true

class InstrumentIssueMailer < ApplicationMailer

  def create(product:, user:, order_detail:, message:, recipients:)
    @product = product
    @user = user
    @message = message
    @order_detail = order_detail
    @order_number = @order_detail.order_number
    @order_detail_link = manage_facility_order_order_detail_url(@order_detail.facility, @order_detail.order, @order_detail)
    reply_to = @user.email
    mail(to: recipients, reply_to: reply_to, subject: text("create.subject", product: product))
  end

  protected

  def translation_scope
    "views.#{self.class.name.underscore}"
  end

end
