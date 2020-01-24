# frozen_string_literal: true

class SetJournalRowsOrderDetailIdNullable < ActiveRecord::Migration[4.2]

  def self.up
    change_column :journal_rows, :order_detail_id, :integer, null: true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
