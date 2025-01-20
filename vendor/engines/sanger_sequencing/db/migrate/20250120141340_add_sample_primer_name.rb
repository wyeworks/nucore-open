# frozen_string_literal: true

class AddSamplePrimerName < ActiveRecord::Migration[4.2]
  def change
    add_column :sanger_sequencing_samples, :primer_name, :string, if_not_exists: true
  end
end
