# frozen_string_literal: true

class AddJournalDateToJournals < ActiveRecord::Migration[4.2]

  def self.up
    add_column :journals, :journal_date, :datetime, null: true
    execute "UPDATE journals SET journal_date = created_at"
    change_column :journals, :journal_date, :datetime, null: false
  end

  def self.down
    remove_column :journals, :journal_date
  end

end
