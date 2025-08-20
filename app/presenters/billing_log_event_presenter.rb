# frozen_string_literal: true

class BillingLogEventPresenter < SimpleDelegator
  def email_to
    email_to = metadata["to"] || []

    if email_to.is_a?(Array)
      email_to.join(", ")
    else
      email_to
    end
  end

  def email_subject
    metadata["subject"]
  end

  def email_notification?
    email_subject && email_to
  end

  def object
    metadata["object"] || loggable_to_s
  end

  def payment_source
    account = loggable&.account
    return nil unless account

    "#{account.account_number} - #{account.description}"
  end
end
