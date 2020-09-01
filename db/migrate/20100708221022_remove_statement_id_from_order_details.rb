# frozen_string_literal: true

class RemoveStatementIdFromOrderDetails < ActiveRecord::Migration[4.2]

  def self.up
    # Oracle will drop the foreign key as part of the remove_column
    remove_foreign_key :order_details, :statements if Nucore::Database.mysql?
    remove_column :order_details, :statement_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
