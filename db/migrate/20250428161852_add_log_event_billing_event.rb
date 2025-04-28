class AddLogEventBillingEvent < ActiveRecord::Migration[7.0]
  def change
    add_column :log_events, :billing_event, :boolean, default: false, null: false
    add_index :log_events, :billing_event
  end
end
