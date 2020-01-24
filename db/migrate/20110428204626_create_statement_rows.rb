# frozen_string_literal: true

class CreateStatementRows < ActiveRecord::Migration[4.2]

  def self.up
    create_table :statement_rows do |t|
      t.column :statement_id, :integer, null: false
      t.column :order_detail_id, :integer, null: false
      t.column :amount, :decimal, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end

  def self.down
    drop_table :statement_rows
  end

end
