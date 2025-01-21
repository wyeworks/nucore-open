# frozen_string_literal: true

class AddSamplePrimerName < ActiveRecord::Migration[4.2]
  def up
    unless ActiveRecord::Base.connection.column_exists?(:sanger_sequencing_samples, :primer_name)
      add_column :sanger_sequencing_samples, :primer_name, :string
    end
  end

  def down
    unless defined?(Acgt)
      remove_column :sanger_sequencing_samples, :primer_name
    end
  end
end
