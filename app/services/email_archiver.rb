# frozen_string_literal: true

class EmailArchiver

  attr_reader :mail_message, :log_event

  def initialize(mail_message:, log_event:)
    @mail_message = mail_message
    @log_event = log_event
  end

  def archive!
    return unless valid?

    ActiveRecord::Base.transaction do
      archived_email = log_event.build_archived_email
      archived_email.save!(validate: false)

      email_content = mail_message.to_s
      filename = "email_#{Time.current.to_i}.eml"
      archived_email.attach_email(email_content, filename: filename)
    end
  rescue StandardError
    nil
  end

  private

  def valid?
    mail_message.present? &&
      log_event&.persisted? &&
      log_event.archived_email.blank?
  end

end
