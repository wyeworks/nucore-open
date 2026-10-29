# frozen_string_literal: true

class JournalRow < ApplicationRecord
  belongs_to :journal
  belongs_to :order_detail, autosave: false

  validates :journal_id, :amount, presence: true
  # Note this is NOT a belongs_to :account. This is an expense account field.
  validates :account, presence: { if: -> { SettingsHelper.feature_on?("accounts.expense_accounts") } }

  delegate :fulfilled_at, to: :order_detail, allow_nil: true

  def update_amount
    update(amount: order_detail.actual_cost)
  end
end
