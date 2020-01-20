# frozen_string_literal: true

class ChangeTimeStampsForEventLog < ActiveRecord::Migration[4.2]
  def change
    change_table :log_events do |t|
      t.datetime :event_time
    end
    change_column_null :log_events, :user_id, true, 0
  end
end
