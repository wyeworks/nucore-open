# frozen_string_literal: true

class JournalRowUpdater
  attr_accessor :order_detail, :journal_rows

  def initialize(order_detail)
    @order_detail = order_detail
    @journal_rows = order_detail.journal_rows
  end

  def update
    if recreate_journal_rows?
      recreate_journal_rows
    else
      update_journal_rows
    end
    self
  end

  def update_journal_rows
    journal_rows.each(&:update_amount)
  end

  def recreate_journal_rows
    journal_rows.group_by(&:journal).each do |journal, rows|
      rows.each(&:destroy)
      JournalRowBuilder.create_for_single_order_detail!(journal, order_detail)
    end
  end

  def recreate_journal_rows?
    account = order_detail.account
    account && account.recreate_journal_rows_on_order_detail_update?
  end
end
