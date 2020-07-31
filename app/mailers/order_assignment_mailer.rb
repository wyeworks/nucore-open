# frozen_string_literal: true

class OrderAssignmentMailer < ApplicationMailer

  def notify_assigned_user(order_details)
    @order_details = Array(order_details)
    return if @order_details.blank?

    @user = @order_details.first.assigned_user
    return if @user.blank?

    mail(to: @user.email, subject: text("notify_assigned_user.subject"))
  end

  protected

  def translation_scope
    "views.order_assignment_mailer"
  end

end
