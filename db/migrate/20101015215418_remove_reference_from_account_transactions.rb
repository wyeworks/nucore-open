# frozen_string_literal: true

class RemoveReferenceFromAccountTransactions < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :account_transactions, :reference
  end

  def self.down
    add_column :account_transactions, :reference, :string, limit: 50, null: true
  end

end
