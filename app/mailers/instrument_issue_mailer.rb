# frozen_string_literal: true

class InstrumentIssueMailer < ApplicationMailer

  def create(product:, user:, message:, recipients:)
    @product = product
    @user = user
    @message = message
    mail(to: recipients, subject: text("create.subject", product: product))
  end

  protected

  def translation_scope
    "views.#{self.class.name.underscore}"
  end

end
