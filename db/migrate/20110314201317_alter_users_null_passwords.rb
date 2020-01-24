# frozen_string_literal: true

class AlterUsersNullPasswords < ActiveRecord::Migration[4.2]

  def self.up
    change_column(:users, :encrypted_password, :string, null: true, default: nil)
    change_column(:users, :password_salt, :string, null: true, default: nil)
  end

  def self.down
    change_column(:users, :encrypted_password, :string, null: false, default: "")
    change_column(:users, :password_salt, :string, null: false, default: "")
  end

end
