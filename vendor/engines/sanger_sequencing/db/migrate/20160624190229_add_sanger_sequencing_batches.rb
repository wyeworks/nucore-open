# frozen_string_literal: true

class AddSangerSequencingBatches < ActiveRecord::Migration[4.2]

  def change
    create_table :sanger_sequencing_batches do |t|
      t.integer :created_by_id, index: true
      t.text :well_plates_raw
      t.timestamps
    end
  end

end
