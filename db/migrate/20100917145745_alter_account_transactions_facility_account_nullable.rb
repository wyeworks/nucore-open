# frozen_string_literal: true

class AlterAccountTransactionsFacilityAccountNullable < ActiveRecord::Migration[4.2]

  def self.up
    change_column :account_transactions, :facility_account_id, :integer, precision: 38, scale: 0, null: true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
