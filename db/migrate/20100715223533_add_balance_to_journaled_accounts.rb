# frozen_string_literal: true

class AddBalanceToJournaledAccounts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :journaled_accounts, :balance, :decimal, null: false, precision: 10, scale: 2
  end

  def self.down
    remove_column :journaled_accounts, :balance
  end

end
