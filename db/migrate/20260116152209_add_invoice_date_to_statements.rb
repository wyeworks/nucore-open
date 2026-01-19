# frozen_string_literal: true

class AddInvoiceDateToStatements < ActiveRecord::Migration[8.0]
  def up
    add_column :statements, :invoice_date, :date, null: true
    execute Nucore::Database.oracle? ? oracle_update : mysql_update
    change_column :statements, :invoice_date, :date, null: false
  end

  def down
    remove_column :statements, :invoice_date
  end

  def mysql_update
    "UPDATE statements SET invoice_date = DATE(created_at)"
  end

  def oracle_update
    "UPDATE statements SET invoice_date = TRUNC(created_at)"
  end
end
