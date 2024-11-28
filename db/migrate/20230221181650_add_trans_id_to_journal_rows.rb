# frozen_string_literal: true

class AddTransIdToJournalRows < ActiveRecord::Migration[6.1]
  def change
    add_column :journal_rows, :trans_id, :string, null: true
  end
end
