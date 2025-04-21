class AddLogEventEventyTypeIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :log_events, :event_type
  end
end
