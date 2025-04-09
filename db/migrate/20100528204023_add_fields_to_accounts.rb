# frozen_string_literal: true

class AddFieldsToAccounts < ActiveRecord::Migration[4.2]

  class Account < ActiveRecord::Base
  end

  def self.up
    add_column :accounts, :expires_at, :datetime, null: true
    Account.update_all(expires_at: DateTime.civil(2012, 1, 1))

    change_column :accounts, :expires_at,         :datetime, null: false

    add_column    :accounts, :name_on_card,       :string, limit: 200, null: true
    add_column    :accounts, :credit_card_number, :text,                  null: true
    add_column    :accounts, :cvv,                :integer,               null: true
    add_column    :accounts, :expiration_month,   :integer,               null: true
    add_column    :accounts, :expiration_year,    :integer,               null: true

    add_column    :accounts, :created_at,         :datetime,              null: true
    Account.update_all(created_at: DateTime.civil(1981, 9, 15))

    change_column :accounts, :created_at,         :datetime,              null: false

    add_column    :accounts, :created_by,         :integer,               null: true
    execute "UPDATE accounts SET created_by = 0"
    change_column :accounts, :created_by,         :integer,               null: false

    add_column    :accounts, :updated_at,         :datetime,              null: true
    add_column    :accounts, :updated_by,         :integer,               null: true
  end

  def self.down
    remove_column :accounts, :expires_at
    remove_column :accounts, :name_on_card
    remove_column :accounts, :credit_card_number
    remove_column :accounts, :cvv
    remove_column :accounts, :expiration_month
    remove_column :accounts, :expiration_year
    remove_column :accounts, :created_at
    remove_column :accounts, :created_by
    remove_column :accounts, :updated_at
    remove_column :accounts, :updated_by
  end

end
