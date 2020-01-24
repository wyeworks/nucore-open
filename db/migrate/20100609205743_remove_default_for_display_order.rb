# frozen_string_literal: true

class RemoveDefaultForDisplayOrder < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :price_groups, :display_order
    add_column :price_groups, :display_order, :integer, precision: 38, scale: 0, null: true
    execute "UPDATE price_groups SET display_order = 1"
    change_column :price_groups, :display_order, :integer, precision: 38, scale: 0, null: false
  end

  def self.down
    remove_column :price_groups, :display_order
    add_column :price_groups, :display_order, :integer, precision: 38, default: 3, scale: 0, null: false
  end

end
