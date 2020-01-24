# frozen_string_literal: true

class AddPaperclipToJournal < ActiveRecord::Migration[4.2]

  def self.up
    add_column :journals, :file_file_name, :string
    add_column :journals, :file_content_type, :string
    add_column :journals, :file_file_size, :integer
    add_column :journals, :file_updated_at, :datetime
  end

  def self.down
    remove_column :journals, :file_file_name
    remove_column :journals, :file_content_type
    remove_column :journals, :file_file_size
    remove_column :journals, :file_updated_at
  end

end
