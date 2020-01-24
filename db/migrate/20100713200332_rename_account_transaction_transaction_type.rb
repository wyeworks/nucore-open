# frozen_string_literal: true

class RenameAccountTransactionTransactionType < ActiveRecord::Migration[4.2]

  def self.up
    rename_column :account_transactions, :transaction_type, :type
  end

  def self.down
    rename_column :account_transactions, :type, :transaction_type
  end

end
