# frozen_string_literal: true

class DropJournalRowsReference < ActiveRecord::Migration[4.2]

  def up
    remove_column :journal_rows, :reference
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

end
