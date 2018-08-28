# frozen_string_literal: true

class EmailFormatValidator < ActiveModel::EachValidator

  EMAIL_PATTERN = /\A[a-z0-9._%+'-]+@[a-z0-9.-]+\.[a-z]{2,6}\z/i

  def validate_each(record, attribute, value)
    return if value.nil?
    record.errors[attribute] << error_message if value !~ EMAIL_PATTERN
  end

  private

  def error_message
    options[:message] || "does not appear to be an email address"
  end

end
