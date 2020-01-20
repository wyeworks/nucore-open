# frozen_string_literal: true

class AddSangerProductGroups < ActiveRecord::Migration[4.2]

  def change
    # sanger_sequencing_product_groups is too long of a table name for Oracle
    create_table :sanger_seq_product_groups do |t|
      t.references :product, null: false, foreign_key: true
      t.index :product_id, unique: true
      t.string :group, null: false
      t.timestamps
    end

    add_column :sanger_sequencing_batches, :group, :string
    add_index :sanger_sequencing_batches, :group
  end

end
