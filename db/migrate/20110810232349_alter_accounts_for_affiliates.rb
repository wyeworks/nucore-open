# frozen_string_literal: true

class AlterAccountsForAffiliates < ActiveRecord::Migration[4.2]

  def self.up
    change_table :accounts do |t|
      t.integer :affiliate_id
      t.string :affiliate_other
    end

    add_index :accounts, :affiliate_id
  end

  def self.down
    remove_index :accounts, :affiliate_id
    remove_column :accounts, :affiliate_id, :affiliate_other
  end

end
