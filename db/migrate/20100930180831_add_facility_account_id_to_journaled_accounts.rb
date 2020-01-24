# frozen_string_literal: true

class AddFacilityAccountIdToJournaledAccounts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :journaled_accounts, :facility_account_id, :integer, null: false
    execute "ALTER TABLE journaled_accounts add CONSTRAINT fk_journaled_accts_fac_act FOREIGN KEY (facility_account_id) REFERENCES facility_accounts (id)"
  end

  def self.down
    remove_column :journaled_accounts, :facility
  end

end
