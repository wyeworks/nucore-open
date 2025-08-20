# frozen_string_literal: true

class Statement < ApplicationRecord
end

class UpdateStatements < ActiveRecord::Migration[7.0]
  def change
    add_column :statements, :parent_statement_id, :integer
    add_foreign_key :statements, :statements, column: :parent_statement_id

    add_column :statements, :invoice_number, :string

    Statement.find_each do |statement|
      statement.update_column(:invoice_number, "#{statement.account_id}-#{statement.id}")
    end
  end
end
