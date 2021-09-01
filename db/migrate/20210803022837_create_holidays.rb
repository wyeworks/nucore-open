# frozen_string_literal: true

class CreateHolidays < ActiveRecord::Migration[5.2]
  def change
    create_table :holidays do |t|
      t.datetime :date, null: false, index: true
      t.timestamps
    end
  end
end
