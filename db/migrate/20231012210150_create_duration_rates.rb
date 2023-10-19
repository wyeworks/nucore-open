# frozen_string_literal: true

class CreateDurationRates < ActiveRecord::Migration[7.0]
  def change
    create_table :duration_rates do |t|
      t.integer  "min_duration"
      t.decimal  "rate", precision: 16, scale: 8
      t.references :product, type: :integer, foreign_key: true, null: false
      t.timestamps
    end
  end
end
