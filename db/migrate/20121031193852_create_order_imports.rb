# frozen_string_literal: true

class CreateOrderImports < ActiveRecord::Migration[4.2]

  def self.up
    create_table :order_imports do |t|
      t.column :upload_file_id, :integer, null: false
      t.column :error_file_id, :integer
      t.column :fail_on_error, :boolean, default: false
      t.column :send_receipts, :boolean, default: false
      t.column :created_by, :integer, null: false
      t.timestamps
    end

    add_index :order_imports, :upload_file_id
    add_index :order_imports, :error_file_id
    add_index :order_imports, :created_by
  end

  def self.down
    remove_index :order_imports, :upload_file_id
    remove_index :order_imports, :error_file_id
    remove_index :order_imports, :created_by

    drop_table :order_imports
  end

end
