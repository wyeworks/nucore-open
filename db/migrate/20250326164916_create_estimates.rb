# frozen_string_literal: true

class CreateEstimates < ActiveRecord::Migration[7.0]
  def change
    create_table :estimates do |t|
      t.string :name
      t.text :note
      t.datetime :expires_at
      t.references :facility, null: false
      t.references :user, null: false
      t.references :created_by, null: false

      t.timestamps
    end
  end
end
