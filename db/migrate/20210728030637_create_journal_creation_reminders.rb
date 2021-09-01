# frozen_string_literal: true

class CreateJournalCreationReminders < ActiveRecord::Migration[5.2]
  def change
    create_table :journal_creation_reminders do |t|
      t.datetime :starts_at
      t.datetime :ends_at
      t.text :message
      t.timestamps
    end
  end
end
