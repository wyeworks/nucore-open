# frozen_string_literal: true

class AddAccountTransactionsTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table   :account_transactions do |t|
      t.references :account,            null: false
      t.references :facility,           null: false
      t.string     :description,        null: false, limit: 200
      t.decimal    :transaction_amount, null: false, precision: 10, scale: 2
      t.decimal    :balance,            null: false, precision: 10, scale: 2
      t.integer    :created_by,         null: false
      t.datetime   :created_at,         null: false
    end

    execute "ALTER TABLE account_transactions add CONSTRAINT fk_act_trans_facilities FOREIGN KEY (facility_id) REFERENCES facilities (id)"
    execute "ALTER TABLE account_transactions add CONSTRAINT fk_act_trans_accounts FOREIGN KEY (account_id) REFERENCES accounts (id)"
  end

  def self.down
    drop_table :account_transactions
  end

end
