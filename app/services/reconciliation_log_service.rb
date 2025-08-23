# frozen_string_literal: true

class ReconciliationLogService
  def initialize(order_details, current_user)
    @order_details = order_details
    @current_user = current_user
  end

  def log_events
    return unless SettingsHelper.feature_on?(:billing_log_events)

    log_events_with_notes
  end

  private

  attr_reader :order_details, :current_user

  def log_events_with_notes
    order_details_by_statement = order_details.group_by(&:statement)

    order_details_by_statement.each do |statement, statement_order_details|
      metadata = build_reconciliation_metadata(statement_order_details)
      LogEvent.log(statement, :closed, current_user, metadata: metadata)
    end
  end

  def build_reconciliation_metadata(order_details)
    metadata = {}

    reconciled_notes = extract_notes(order_details, "Reconciled", :reconciled_note)
    unrecoverable_notes = extract_notes(order_details, "Unrecoverable", :unrecoverable_note)

    metadata[:reconciled_notes] = reconciled_notes if reconciled_notes.any?
    metadata[:unrecoverable_notes] = unrecoverable_notes if unrecoverable_notes.any?

    metadata
  end

  def extract_notes(order_details, status_name, note_field)
    order_details
      .select { |od| od.order_status.name == status_name }
      .filter_map { |od| od.send(note_field) }
      .uniq
  end
end
