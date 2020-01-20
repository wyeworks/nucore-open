# frozen_string_literal: true

class ChangeAccountTransactionsDescriptionToNullable < ActiveRecord::Migration[4.2]

  def self.up
    change_column :account_transactions, :description, :string, limit: 200, null: true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
