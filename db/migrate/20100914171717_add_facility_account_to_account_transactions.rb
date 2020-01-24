# frozen_string_literal: true

class AddFacilityAccountToAccountTransactions < ActiveRecord::Migration[4.2]

  def self.up
    change_table :account_transactions do |t|
      t.references :facility_account, null: false
    end
    execute "ALTER TABLE account_transactions ADD CONSTRAINT fk_int_at_fa FOREIGN KEY (facility_account_id) REFERENCES facility_accounts (id)"
  end

  def self.down
    remove_column :account_transactions, :facility_account_id
  end

end
