# frozen_string_literal: true

class StatementPresenter < SimpleDelegator

  include Rails.application.routes.url_helpers
  include DateHelper

  def self.wrap(statements)
    statements.map { |statement| new(statement) }
  end

  def download_path
    facility_account_statement_path(facility, account, id, format: :pdf)
  end

  def order_count
    order_details.count
  end

  def sent_at
    I18n.l(created_at, format: :usa)
  end

  def sent_by
    User.find(created_by).full_name
  rescue ActiveRecord::RecordNotFound
    I18n.t("statements.show.created_by.unknown")
  end

  def closed_by_user_full_names
    closed_events.map { |event| event.user.full_name }
  end

  def closed_by_times
    closed_events.map { |event| format_usa_datetime(event.event_time) }
  end

  def reconciled_at_times
    order_details.where.not(reconciled_at: nil)
                 .order(reconciled_at: :desc)
                 .pluck(:reconciled_at)
                 .uniq
                 .map { |time| format_usa_datetime(time) }
  end

  def reconcile_notes
    @reconcile_notes ||= if status == :reconciled
                           order_details_notes(:reconciled_note)
                         elsif status == :unrecoverable
                           order_details_notes(:unrecoverable_note)
                         end
  end

end
