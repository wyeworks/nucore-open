# frozen_string_literal: true

class AddRelayTypeToProducts < ActiveRecord::Migration[4.2]

  def self.up
    add_column :products, :relay_type, :string, limit: 50, null: true
    execute "UPDATE products SET relay_type = 'SynaccessRevA'"
  end

  def self.down
    remove_column :products, :relay_type
  end

end
