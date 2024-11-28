# frozen_string_literal: true

class AddRef3ToJournalRows < ActiveRecord::Migration[7.0]
  def change
    add_column :journal_rows, :trans_3rd_ref, :string
  end
end
