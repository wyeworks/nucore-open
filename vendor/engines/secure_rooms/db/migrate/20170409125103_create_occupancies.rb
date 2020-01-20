# frozen_string_literal: true

class CreateOccupancies < ActiveRecord::Migration[4.2]

  def change
    create_table :secure_rooms_occupancies do |t|
      t.references :product, null: false, index: true, foreign_key: true
      t.references :user, null: false, index: true, foreign_key: true
      t.references :account, index: true, foreign_key: true

      t.references :entry_event, index: true
      t.datetime :entry_at
      t.references :exit_event, index: true
      t.datetime :exit_at

      t.datetime :orphaned_at

      t.timestamps null: false
    end

    add_foreign_key :secure_rooms_occupancies, :secure_rooms_events, column: :entry_event_id
    add_foreign_key :secure_rooms_occupancies, :secure_rooms_events, column: :exit_event_id
  end

end
