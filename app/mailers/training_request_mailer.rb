# frozen_string_literal: true

class TrainingRequestMailer < ApplicationMailer
  def notify_facility_staff(user, product)
    @user = user
    @product = product
    reply_to = @user.email
    return unless @product.training_request_contacts.any?

    mail(to: @product.training_request_contacts, reply_to:, subject: t("training_request_mailer.notify_facility_staff.subject", facility: @product.facility))
  end
end
