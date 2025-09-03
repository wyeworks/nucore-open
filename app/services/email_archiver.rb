# frozen_string_literal: true

class EmailArchiver

  attr_reader :mail_message, :log_event

  def initialize(mail_message:, log_event:)
    @mail_message = mail_message
    @log_event = log_event
  end

  def archive!
    return unless valid?

    email_content = mail_message.to_s
    filename = "email_#{Time.current.strftime('%Y%m%d_%H%M%S')}.eml"
    log_event.attach_email(email_content, filename:)
  rescue StandardError
    nil
  end

  private

  def valid?
    mail_message.present? &&
      log_event&.persisted? &&
      !log_event.email_file_present?
  end

end
