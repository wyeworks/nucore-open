# frozen_string_literal: true

class CreatePaymentsReceived < ActiveRecord::Migration[4.2]

  def up
    create_table :payments do |t|
      t.references :account, null: false
      t.references :statement
      t.string :source, null: false
      t.string :source_id
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.references :paid_by, null: true
      t.timestamps null: false
    end
    add_foreign_key :payments, :statements
    add_index :payments, :statement_id
    add_foreign_key :payments, :accounts
    add_index :payments, :account_id
    add_foreign_key :payments, :users, column: :paid_by_id
    add_index :payments, :paid_by_id
  end

  def down
    drop_table :payments
  end

end
