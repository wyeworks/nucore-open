# frozen_string_literal: true

class AddAlsNumberToJournals < ActiveRecord::Migration[5.2]
  def change
    create_table :umass_corum_als_sequence_numbers do |t|
      t.timestamps
    end
    add_column :journals, :als_number, :string
  end
end
