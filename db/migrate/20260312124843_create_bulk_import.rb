# frozen_string_literal: true

class CreateBulkImport < ActiveRecord::Migration[8.0]
  def change
    create_table :bulk_imports do |t|
      t.string :import_type, null: false
      t.string :status
      t.integer :created_by_id, null: false
      t.text :data

      t.timestamps
    end

    add_index :bulk_imports, [:created_at, :import_type]
  end
end
