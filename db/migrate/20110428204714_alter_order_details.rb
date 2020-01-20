# frozen_string_literal: true

class AlterOrderDetails < ActiveRecord::Migration[4.2]

  def self.up
    change_table :order_details do |t|
      t.column :fulfilled_at, :datetime
      t.column :reviewed_at, :datetime
      t.column :statement_id, :integer
      t.column :journal_id, :integer
      t.column :reconciled_note, :string
    end
  end

  def self.down
    change_table :order_details do |t|
      t.remove :fulfilled_at
      t.remove :reviewed_at
      t.remove :statement_id
      t.remove :journal_id
      t.remove :reconciled_note
    end
  end

end
