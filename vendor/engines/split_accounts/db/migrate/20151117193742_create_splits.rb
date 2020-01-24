# frozen_string_literal: true

class CreateSplits < ActiveRecord::Migration[4.2]

  def up
    create_table :splits do |t|
      t.integer :parent_split_account_id, null: false
      t.integer :subaccount_id, null: false
      t.decimal :percent, precision: 6, scale: 3, null: false
      t.boolean :extra_penny, null: false
    end

    add_index :splits, :parent_split_account_id
    add_index :splits, :subaccount_id
  end

  def down
    drop_table :splits
  end

end
