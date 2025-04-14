# frozen_string_literal: true

class ProblemOrderMailer < ApplicationMailer

  def notify_user(order_detail)
    @order_detail = order_detail
    @user = @order_detail.user
    reply_to = @order_detail.facility.email || Settings.email.from
    mail(to: @user.email, reply_to: reply_to, subject: text("notify_user.subject", facility: @order_detail.facility.abbreviation))
  end

  def notify_user_with_resolution_option(order_detail)
    @order_detail = order_detail
    @user = @order_detail.user
    reply_to = @order_detail.facility.email || Settings.email.from
    mail(to: @user.email, reply_to: reply_to, subject: text("notify_user.subject", facility: @order_detail.facility.abbreviation))
  end

  protected

  def translation_scope
    "views.problem_order_mailer"
  end

end
