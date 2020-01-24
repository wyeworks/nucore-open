# frozen_string_literal: true

class AddDisplayAccountNumberToAccounts < ActiveRecord::Migration[4.2]

  def self.up
    change_table :accounts do |t|
      t.string :display_account_number, limit: 50
    end
  end

  def self.down
    remove_column :accounts, :display_account_number
  end

end
