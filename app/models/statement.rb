# frozen_string_literal: true

class Statement < ApplicationRecord

  has_many :order_details, inverse_of: :statement
  has_many :statement_rows, dependent: :destroy
  has_many :payments, inverse_of: :statement

  has_many :closed_events,
           -> { where(event_type: "closed") },
           class_name: "LogEvent",
           as: :loggable

  belongs_to :account
  belongs_to :facility
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by

  validates_numericality_of :account_id, :facility_id, :created_by, only_integer: true

  default_scope -> { order(created_at: :desc) }

  scope :for_accounts, ->(accounts) { where(account_id: accounts) if accounts.present? }
  scope :for_account_admins, lambda { |account_admins|
    where(account: Account.joins(:notify_users).where(account_users: { user_id: account_admins })) if account_admins.present?
  }

  scope :created_between, lambda { |start_at, end_at|
    if start_at
      where(created_at: start_at..(end_at || DateTime::Infinity.new))
    elsif end_at
      where(arel_table[:created_at].lt(end_at))
    end
  }

  scope :reconciled, -> { where(canceled_at: nil).where.not(id: OrderDetail.unreconciled.where.not(statement_id: nil).select(:statement_id)) }
  scope :unreconciled, -> { where(canceled_at: nil).where(id: OrderDetail.unreconciled.where.not(statement_id: nil).select(:statement_id)) }
  scope :unrecoverable, -> { where(canceled_at: nil).where(id: OrderDetail.unrecoverable.where.not(statement_id: nil).select(:statement_id)) }

  # Use this for restricting the the current facility
  scope :for_facility, ->(facility) { where(facility:) if facility.single_facility? }
  # Use this for restricting based on search parameters
  scope :for_facilities, ->(facilities) { where(facility: facilities) if facilities.present? }

  def total_cost
    statement_rows.inject(0) { |sum, row| sum += row.amount }
  end

  def invoice_number
    "#{account_id}-#{id}"
  end

  def self.find_by_statement_id(query)
    return nil unless /\A(?<id>\d+)\z/ =~ query
    find_by(id:)
  end

  def self.find_by_invoice_number(query)
    where_invoice_number(query)&.first
  end

  def self.where_invoice_number(query)
    return none unless /\A(?<account_id>\d+)-(?<id>\d+)\z/ =~ query
    where(id:, account_id:)
  end

  def order_details_notes(note_field)
    order_details.filter_map do |od|
      od.send(note_field)&.strip.presence
    end.uniq
  end

  def invoice_date
    created_at.to_date
  end

  def reconciled?
    order_details.unreconciled.empty? && canceled_at.blank?
  end

  # A statement is unrecoverable if it has at least one unrecoverable order detail
  def unrecoverable?
    order_details.unrecoverable.present? && canceled_at.blank?
  end

  def can_cancel?
    order_details.reconciled.empty? && canceled_at.blank?
  end

  def status
    if canceled_at
      :canceled
    elsif reconciled?
      :reconciled
    elsif unrecoverable?
      :unrecoverable
    else
      :unreconciled
    end
  end

  def paid_in_full?
    payments.sum(:amount) >= total_cost
  end

  def add_order_detail(order_detail)
    statement_rows << StatementRow.new(order_detail:)
    order_details << order_detail
  end

  def remove_order_detail(order_detail)
    rows_for_order_detail(order_detail).each(&:destroy)
  end

  def rows_for_order_detail(order_detail)
    statement_rows.where(order_detail_id: order_detail.id)
  end

  def to_log_s
    "Statement: #{invoice_number}"
  end

  def users_to_notify
    account.notify_users.map do |user|
      "#{user.full_name} <#{user.email}>"
    end
  end

  def send_emails
    account.notify_users.each do |user|
        Notifier.statement(
          user:,
          facility:,
          account:,
          statement: self
        ).deliver_later
    end
  end

  def cross_core_order_details
    order_details.cross_core
  end

  def cross_core_order_details_from_other_facilities
    cross_core_order_details
      .where.not(projects: { facility: })
  end

  def display_cross_core_messsage?
    cross_core_order_details_from_other_facilities.any?
  end

end
