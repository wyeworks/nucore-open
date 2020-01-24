# frozen_string_literal: true

class AddBatchIdToSubmissions < ActiveRecord::Migration[4.2]

  def change
    add_column :sanger_sequencing_submissions, :batch_id, :integer, index: true
    add_foreign_key :sanger_sequencing_submissions, :sanger_sequencing_batches,
                    column: :batch_id, on_delete: :nullify
  end

end
