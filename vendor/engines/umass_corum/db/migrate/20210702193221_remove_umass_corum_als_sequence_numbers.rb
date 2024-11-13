# frozen_string_literal: true

class RemoveUmassCorumAlsSequenceNumbers < ActiveRecord::Migration[5.2]
  def up
    drop_table :umass_corum_als_sequence_numbers
  end

  def down
    create_table :umass_corum_als_sequence_numbers do |t|
      t.timestamps
    end
  end
end
