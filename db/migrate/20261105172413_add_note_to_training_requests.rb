# frozen_string_literal: true

class AddNoteToTrainingRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :training_requests, :note, :text
    add_column :training_requests, :note_updated_at, :datetime
    add_column :training_requests, :note_updated_by_id, :integer
    add_foreign_key :training_requests, :users, column: :note_updated_by_id
    add_index :training_requests, :note_updated_by_id
  end
end
