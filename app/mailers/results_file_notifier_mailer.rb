# frozen_string_literal: true

class ResultsFileNotifierMailer < ApplicationMailer

  def file_uploaded(file)
    @order_detail = file.order_detail
    product = @order_detail.product
    product_email = product.email
    reply_to = product_email || SettingsHelper.setting("email.from")

    mail(reply_to: reply_to, to: @order_detail.user.email, subject: text("results_file_notifier_mailer.file_uploaded.subject"))
  end

end
