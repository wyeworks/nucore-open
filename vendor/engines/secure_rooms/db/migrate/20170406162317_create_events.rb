# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[4.2]

  def change
    create_table :secure_rooms_events do |t|
      t.references :card_reader
      t.references :user

      t.datetime :occurred_at
      t.string :outcome
      t.string :outcome_details

      t.timestamps null: false
    end

    add_index :secure_rooms_events, :user_id
    add_index :secure_rooms_events, :card_reader_id
  end

end
