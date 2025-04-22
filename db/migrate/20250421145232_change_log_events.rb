# frozen_string_literal: true

class ChangeLogEvents < ActiveRecord::Migration[7.0]
  def change
    add_index :log_events, :event_type
    add_index :log_events, :event_time
  end
end
