# frozen_string_literal: true

class AddJournaledAtToJournals < ActiveRecord::Migration[7.0]
  def change
    add_column :journals, :journaled_at, :datetime
  end
end
