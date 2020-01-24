# frozen_string_literal: true

class AlterUsersAddUid < ActiveRecord::Migration[4.2]

  def self.up
    add_column :users, :uid, :integer
    add_index :users, :uid
  end

  def self.down
    remove_index :users, :uid
    remove_column :users, :uid
  end

end
