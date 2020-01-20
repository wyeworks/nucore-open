# frozen_string_literal: true

class CreateUserRoles < ActiveRecord::Migration[4.2]

  def self.up
    create_table :user_roles do |t|
      t.integer :user_id, null: false
      t.integer :facility_id
      t.string :role, null: false
    end

    add_index(:user_roles, [:user_id, :facility_id, :role])
  end

  def self.down
    remove_index(:user_roles, [:user_id, :facility_id, :role])
    drop_table :user_roles
  end

end
