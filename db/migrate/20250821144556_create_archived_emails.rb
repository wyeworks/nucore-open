class CreateArchivedEmails < ActiveRecord::Migration[7.0]
  def change
    create_table :archived_emails do |t|
      t.integer :log_event_id, null: false, index: true

      t.timestamps
    end

    add_foreign_key :archived_emails, :log_events
  end
end
