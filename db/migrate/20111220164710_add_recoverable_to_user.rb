# frozen_string_literal: true

class AddRecoverableToUser < ActiveRecord::Migration[4.2]

  def self.up
    change_table :users do |t|
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
    end
  end

  def self.down
    remove_column :users, :reset_password_token
    remove_column :users, :reset_password_sent_at
  end

end
