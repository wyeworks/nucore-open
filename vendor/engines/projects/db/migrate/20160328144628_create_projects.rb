# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[4.2]

  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.references :facility, null: false

      t.timestamps null: false
    end

    add_index :projects, [:facility_id, :name], unique: true
    add_index :projects, :facility_id
    add_foreign_key :projects, :facilities
  end

end
