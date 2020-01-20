# frozen_string_literal: true

class AddJournalCutoffs < ActiveRecord::Migration[4.2]

  def change
    create_table :journal_cutoff_dates do |t|
      t.datetime :cutoff_date
      t.timestamps null: false
    end
  end

end
