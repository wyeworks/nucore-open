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
    if event_type == "review_orders_email" && order_ids.present?
      "#{metadata['object'] || loggable_to_s} (Orders: #{order_ids_display})"
    else
      metadata["object"] || loggable_to_s
    end
  end

  def order_ids
    metadata["order_ids"] || []
  end

  def order_ids_display
    return nil if order_ids.blank?

    if order_ids.length > 5
      "#{order_ids.first(5).join(', ')}, and #{order_ids.length - 5} more"
    else
      order_ids.join(", ")
    end
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
    notes = []

    if reconciled_notes.present?
      reconciled_notes.each do |note|
        notes << "Reconciled: #{note}"
      end
    end

    if unrecoverable_notes.present?
      unrecoverable_notes.each do |note|
        notes << "Unrecoverable: #{note}"
      end
    end

    notes
  end

end
