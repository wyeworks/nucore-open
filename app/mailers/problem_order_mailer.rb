# frozen_string_literal: true

class ProblemOrderMailer < ApplicationMailer

  def notify_user(order_detail)
    problem_order_email(order_detail)
  end

  def notify_user_with_resolution_option(order_detail)
    problem_order_email(order_detail)
  end

  protected

  def translation_scope
    "views.problem_order_mailer"
  end

  private

  def problem_order_email(order_detail)
    @order_detail = order_detail
    @user = order_detail.user

    mail(
      to: @user.email,
      reply_to: order_detail.facility.email || Settings.email.from,
      subject: text("notify_user.subject"),
    )
  end

end
