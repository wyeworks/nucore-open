# frozen_string_literal: true

module BulkEmail

  class Mailer < BaseMailer

    def send_mail(recipient:, subject:, body:, reply_to: nil, facility:)
      @recipient = recipient
      @body = body
      @facility = facility
      options = { from: sender, to: recipient.email, subject: subject }
      options[:reply_to] = reply_to if reply_to.present?
      mail(options)
    end

    def sender
      if @facility.try(:single_facility?)
        "#{@facility.name} <#{default_params[:from]}>"
      else
        default_params[:from]
      end
    end

  end

end
