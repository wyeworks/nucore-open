# frozen_string_literal: true

class FixSangerSequencingSubmissionCascadesForOracle < ActiveRecord::Migration[4.2]

  def change
    # Oracle does not support on_update so we need to remove and re-add it to keep
    # consistent with the MySQL installations
    remove_foreign_key :sanger_sequencing_samples, column: :submission_id
    add_foreign_key :sanger_sequencing_samples, :sanger_sequencing_submissions, column: :submission_id, on_delete: :cascade
  end

end
