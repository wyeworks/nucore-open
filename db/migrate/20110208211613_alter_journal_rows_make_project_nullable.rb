# frozen_string_literal: true

class AlterJournalRowsMakeProjectNullable < ActiveRecord::Migration[4.2]

  def self.up
    change_column :journal_rows, :project, :integer, null: true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end

end
