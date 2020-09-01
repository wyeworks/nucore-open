# frozen_string_literal: true

class ChangeVestalVersions < ActiveRecord::Migration[4.2]

  def self.up
    add_column :versions, :reason_for_update, :string
    add_column :versions, :reverted_from, :integer
    add_column :versions, :commit_label, :string

    rename_column :versions, :data_changes, :modifications

    if Nucore::Database.oracle?
      execute %( ALTER TABLE versions RENAME COLUMN "NUMBER" TO "VERSION_NUMBER" )
    else
      rename_column :versions, :number, :version_number
    end

    add_index :versions, :commit_label
  end

  def self.down
    remove_index :versions, :commit_label

    if Nucore::Database.oracle?
      execute %( ALTER TABLE versions RENAME COLUMN "VERSION_NUMBER" TO "NUMBER" )
    else
      rename_column :versions, :version_number, :number
    end

    rename_column :versions, :modifications, :data_changes
    remove_columns :versions, :reason_for_update, :reverted_from, :commit_label
  end

end
