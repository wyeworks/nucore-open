# frozen_string_literal: true

module ArchivedEmailSupport
  extend ActiveSupport::Concern

  included do
    has_one_attached :email_file
  end

  def attach_email(email_content, filename: nil)
    filename ||= "email_#{Time.current.to_i}.eml"

    email_file.attach(
      io: StringIO.new(email_content),
      filename: filename,
      content_type: "message/rfc822"
    )
  end

  def email_content
    email_file.download if email_file_present?
  end

  def email_file_present?
    email_file.attached?
  end
end
