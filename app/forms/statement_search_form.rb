# frozen_string_literal: true

class StatementSearchForm

  include DateHelper
  include ActiveModel::Model

  attr_accessor :accounts, :current_facility, :facilities, :account_admins, :status, :date_range_start, :date_range_end

  def available_accounts
    Account.where(id: all_statements.select(:account_id)).order(:account_number, :description)
  end

  def available_account_admins
    # Oracle throws an error if there is an ORDER in a subquery
    User.where(id: available_accounts.unscope(:order).joins(:notify_users).select("account_users.user_id")).order(:last_name, :first_name)
  end

  def available_statuses
    ["Reconciled", "Unreconciled", "Unrecoverable", "Canceled"]
  end

  def facility_filter?
    current_facility.cross_facility?
  end

  def available_facilities
    Facility.where(id: all_statements.select(:facility_id)).order(:name)
  end

  def search
    results = all_statements
              .for_facilities(facilities) # ANDs with the current facility so
              .for_accounts(accounts)
              .for_account_admins(account_admins)
              .created_between(parse_usa_date(date_range_start)&.beginning_of_day, parse_usa_date(date_range_end)&.end_of_day)
    add_reconciled_status_filter(results)
  end

  private

  def add_reconciled_status_filter(results)
    case status
    when "Reconciled"
      results.reconciled
    when "Unreconciled"
      results.unreconciled
    when "Unrecoverable"
      results.unrecoverable
    when "Canceled"
      results.where.not(canceled_at: nil)
    else
      results
    end
  end

  def all_statements
    # Oracle throws an error if there is an ORDER in a subquery and Statements have a default scope/order
    Statement.for_facility(current_facility).unscope(:order)
  end

end
