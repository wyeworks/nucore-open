# frozen_string_literal: true

class AddNoteToTrainingRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :training_requests, :note, :text
  end
end
