# frozen_string_literal: true

class CreateUserPreferences < ActiveRecord::Migration[4.2]
  def change
    create_table :user_preferences do |t|
      t.references :user, foreign_key: true
      t.string :name, null: false
      t.string :value, null: false

      t.timestamps null: false
    end

    add_index :user_preferences, [:user_id, :name], unique: true
  end
end
