# frozen_string_literal: true

class ArchivedEmail < ApplicationRecord

  belongs_to :log_event
  has_one_attached :email_file

  validates :email_file, attached: true

  def attach_email(email_content, filename: nil)
    filename ||= "email_#{Time.current.to_i}.eml"

    email_file.attach(
      io: StringIO.new(email_content),
      filename: filename,
      content_type: "message/rfc822"
    )
  end

  def email_content
    email_file.download if email_file.attached?
  end

  def email_file_present?
    email_file.attached?
  end

end
