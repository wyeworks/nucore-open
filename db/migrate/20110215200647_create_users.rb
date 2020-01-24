# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[4.2]

  def self.up
    create_table(:users) do |t|
      t.string :username, null: false
      t.string :first_name
      t.string :last_name
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :password_salt

      t.integer  :sign_in_count, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
  end

  def self.down
    drop_table :users
  end

end
