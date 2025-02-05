# frozen_string_literal: true

class AddFacilityToPrimer < ActiveRecord::Migration[7.0]
  def change
    add_column :sanger_sequencing_primers, :facility_id, :integer, index: true, null: false
  end
end
