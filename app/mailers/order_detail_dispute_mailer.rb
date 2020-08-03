# frozen_string_literal: true

class OrderDetailDisputeMailer < ApplicationMailer

  add_template_helper DateHelper

  def dispute_resolved(order_detail:, user:)
    @order_detail = order_detail
    @user = user
    mail(
      to: @user.email,
      subject: text("subject", facility_abbreviation: @order_detail.facility.abbreviation),
    )
  end

  protected

  def translation_scope
    "views.order_detail_dispute_mailer.dispute_resolved"
  end

end
