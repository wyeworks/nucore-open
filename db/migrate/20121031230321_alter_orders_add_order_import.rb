# frozen_string_literal: true

class AlterOrdersAddOrderImport < ActiveRecord::Migration[4.2]

  def self.up
    add_column :orders, :order_import_id, :integer
    add_index :orders, :order_import_id
  end

  def self.down
    remove_column :orders, :order_import_id
    remove_index :orders, :order_import_id
  end

end
