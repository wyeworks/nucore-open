# frozen_string_literal: true

class AddInDisputeToAccountTransactions < ActiveRecord::Migration[4.2]

  def self.up
    add_column :account_transactions, :is_in_dispute, :boolean, null: true
    execute "UPDATE account_transactions set is_in_dispute = 0"
    change_column :account_transactions, :is_in_dispute, :boolean, null: false
  end

  def self.down
    remove_column :account_transactions, :is_in_dispute
  end

end
