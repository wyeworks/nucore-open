# frozen_string_literal: true

class AddAccountTransactionIdToJournalRows < ActiveRecord::Migration[4.2]

  def self.up
    add_column :journal_rows, :account_transaction_id, :integer, null: true
    execute "ALTER TABLE journal_rows ADD CONSTRAINT fk_jour_row_act_txn FOREIGN KEY (account_transaction_id) REFERENCES account_transactions (id)"
  end

  def self.down
    remove_column :journal_rows, :account_transaction_id
  end

end
