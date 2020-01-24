# frozen_string_literal: true

class AddAttachmentsFileToFileUpload < ActiveRecord::Migration[4.2]

  def self.up
    add_column :file_uploads, :file_file_name, :string
    add_column :file_uploads, :file_content_type, :string
    add_column :file_uploads, :file_file_size, :integer
    add_column :file_uploads, :file_updated_at, :datetime

    remove_column :file_uploads, :content_type # unused column
  end

  def self.down
    remove_column :file_uploads, :file_file_name
    remove_column :file_uploads, :file_content_type
    remove_column :file_uploads, :file_file_size
    remove_column :file_uploads, :file_updated_at

    add_column :file_uploads, :content_type, :string # old column
  end

end
