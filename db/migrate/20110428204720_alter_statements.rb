# frozen_string_literal: true

class AlterStatements < ActiveRecord::Migration[4.2]

  def self.up
    change_table :statements do |t|
      t.column :account_id, :integer
    end
  end

  def self.down
    change_table :statements do |t|
      t.remove :account_id
    end
  end

end
