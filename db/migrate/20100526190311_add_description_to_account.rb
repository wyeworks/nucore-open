# frozen_string_literal: true

class AddDescriptionToAccount < ActiveRecord::Migration[4.2]

  def self.up
    add_column :accounts, :description, :string, limit: 200, null: true
    execute "UPDATE accounts SET description = 'description'"
    change_column :accounts, :description, :string, limit: 200, null: false
  end

  def self.down
    remove_column :accounts, :description
  end

end
