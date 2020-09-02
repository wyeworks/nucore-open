# frozen_string_literal: true

class AlterJournalRowsRemoveNu < ActiveRecord::Migration[4.2]

  def self.up
    if Nucore::Database.oracle?
      puts <<-WARN
        >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        You're running Oracle. Doing so usually requires NU columns on journal_rows. This migration removes those
        columns! If you really want to run this migration on Oracle you need to rollback to the previous migration
        version and remove the condition that caused this message.
        <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      WARN
    else
      remove_columns :journal_rows, :dept, :fund, :activity, :program, :project
    end
  end

  def self.down
    change_table :journal_rows do |t|
      t.column :fund, :string, limit: 3, null: false
      t.column :dept, :string, limit: 7, null: false
      t.column :project, :string, limit: 8
      t.column :activity, :string, limit: 2
      t.column :program, :string, limit: 4
    end
  end

end
