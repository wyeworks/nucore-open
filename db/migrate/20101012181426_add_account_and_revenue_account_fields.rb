# frozen_string_literal: true

class AddAccountAndRevenueAccountFields < ActiveRecord::Migration[4.2]

  def self.up
    add_column :products, :account, :integer, null: true
    add_column :facility_accounts, :revenue_account, :integer, null: true
    execute "UPDATE products SET account = 12345"
    execute "UPDATE facility_accounts SET revenue_account = 12345"
    change_column :products, :account, :integer, null: false
    change_column :facility_accounts, :revenue_account, :integer, null: false
  end

  def self.down
    remove_column :products, :account
    remove_column :facility_accounts, :revenue_account
  end

end
