# frozen_string_literal: true

class RemoveCvvFromAccounts < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :accounts, :cvv
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
