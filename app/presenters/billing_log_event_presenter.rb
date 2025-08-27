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

  def order_ids
    metadata["order_ids"] || []
  end

  def has_orders?
    order_ids.present?
  end

  def reconciled_notes
    metadata["reconciled_notes"] || []
  end

  def unrecoverable_notes
    metadata["unrecoverable_notes"] || []
  end

  def has_reconciliation_data?
    event_type == "closed" && loggable_type == "Statement" &&
      (reconciled_notes.present? || unrecoverable_notes.present?)
  end

  def all_reconciliation_notes
    notes = reconciled_notes.map do |note|
      "Reconciled: #{note}"
    end

    unrecoverable_notes.each do |note|
      notes << "Unrecoverable: #{note}"
    end

    notes
  end

  def payment_source
    return unless loggable.respond_to?(:account)

    account = loggable.account
    return unless account

    "#{account.account_number} - #{account.description}"
  end
end
