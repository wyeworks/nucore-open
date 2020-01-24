# frozen_string_literal: true

class RenameFilesTable < ActiveRecord::Migration[4.2]

  def self.up
    rename_table :files, :file_uploads
  end

  def self.down
    rename_table :file_uploads, :files
  end

end
