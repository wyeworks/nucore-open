class AddMetadataToLogEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :log_events, :metadata, :text 
  end
end
