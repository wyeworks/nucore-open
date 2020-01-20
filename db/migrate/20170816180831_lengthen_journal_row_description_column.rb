# frozen_string_literal: true

class LengthenJournalRowDescriptionColumn < ActiveRecord::Migration[4.2]

  def up
    change_column :journal_rows, :description, :string, limit: 512
  end

  def down
    change_column :journal_rows, :description, :string, limit: 200
  end

end
