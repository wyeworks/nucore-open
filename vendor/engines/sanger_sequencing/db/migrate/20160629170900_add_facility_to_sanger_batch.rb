# frozen_string_literal: true

class AddFacilityToSangerBatch < ActiveRecord::Migration[4.2]

  def change
    add_reference :sanger_sequencing_batches, :facility, index: true
    add_foreign_key :sanger_sequencing_batches, :facilities
  end

end
