# frozen_string_literal: true

class AddCustomerSampleIdToSangerSequencing < ActiveRecord::Migration[4.2]

  def change
    add_column :sanger_sequencing_samples, :customer_sample_id, :string
  end

end
