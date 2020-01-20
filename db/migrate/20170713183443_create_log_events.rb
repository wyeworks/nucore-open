# frozen_string_literal: true

class CreateLogEvents < ActiveRecord::Migration[4.2]
  def change
    create_table :log_events do |t|
      t.references :loggable, polymorphic: true
      t.string :event_type
      t.references :user, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end

    add_index(:log_events, [:loggable_type, :loggable_id],
              name: "index_log_events_loggable")
  end
end
