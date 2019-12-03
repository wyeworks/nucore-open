# frozen_string_literal: true

class Statement < ApplicationRecord

  has_many :order_details, inverse_of: :statement
  has_many :statement_rows, dependent: :destroy
  has_many :payments, inverse_of: :statement

  belongs_to :account
  belongs_to :facility
  belongs_to :created_by_user, class_name: "User", foreign_key: :created_by

  validates_numericality_of :account_id, :facility_id, :created_by, only_integer: true

  default_scope -> { order(created_at: :desc) }

  scope :for_accounts, ->(accounts) { where(account_id: accounts) if accounts.present? }
  scope :for_sent_to, lambda { |sent_to|
    where(account: Account.joins(:notify_users).where(account_users: { user_id: sent_to })) if sent_to.present?
  }

  scope :created_between, lambda { |start_at, end_at|
    if start_at
      where(created_at: start_at..(end_at || DateTime::Infinity.new))
    elsif end_at
      where(arel_table[:created_at].lt(end_at))
    end
  }

  scope :reconciled, -> { where.not(id: OrderDetail.unreconciled.where.not(statement_id: nil).select(:statement_id)) }
  scope :unreconciled, -> { where(id: OrderDetail.unreconciled.where.not(statement_id: nil).select(:statement_id)) }

  # Use this for restricting the the current facility
  scope :for_facility, ->(facility) { where(facility: facility) if facility.single_facility? }
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
    find_by(id: id)
  end

  def self.find_by_invoice_number(query)
    return nil unless /\A(?<account_id>\d+)-(?<id>\d+)\z/ =~ query
    find_by(id: id, account_id: account_id)
  end

  def invoice_date
    created_at.to_date
  end

  def reconciled?
    order_details.unreconciled.empty?
  end

  def paid_in_full?
    payments.sum(:amount) >= total_cost
  end

  def add_order_detail(order_detail)
    statement_rows << StatementRow.new(order_detail: order_detail)
    order_details << order_detail
  end

  def remove_order_detail(order_detail)
    rows_for_order_detail(order_detail).each(&:destroy)
  end

  def rows_for_order_detail(order_detail)
    statement_rows.where(order_detail_id: order_detail.id)
  end

end
