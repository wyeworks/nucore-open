# frozen_string_literal: true

module BulkEmail

  class Mailer < ApplicationMailer

    def send_mail(recipient:, subject:, body:, reply_to: nil, facility:)
      @recipient = recipient
      @body = body
      @facility = facility
      options = { from: sender, to: recipient.email, subject: subject }
      options[:reply_to] = reply_to if reply_to.present?
      mail(options)
    end

    def sender
      address = Mail::Address.new(default_params[:from])
      address.display_name = @facility.name if @facility.try(:single_facility?)
      address
    end

  end

end
