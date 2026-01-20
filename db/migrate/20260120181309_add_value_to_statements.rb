# frozen_string_literal: true

class AddValueToStatements < ActiveRecord::Migration[8.0]
  def change
    add_column :statements, :value, :boolean, default: false, null: true
  end
end
