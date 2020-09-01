# frozen_string_literal: true

class CreateSangerSequencingSubmissions < ActiveRecord::Migration[4.2]

  def up
    create_table :sanger_sequencing_submissions do |t|
      t.integer :order_detail_id
      t.timestamps
    end

    add_index :sanger_sequencing_submissions, :order_detail_id

    # sequence_start_value is oracle-specific, but mysql throws it away
    create_table :sanger_sequencing_samples, sequence_start_value: 11_111 do |t|
      t.integer :submission_id, null: false
      t.foreign_key :sanger_sequencing_submissions, column: :submission_id, on_delete: :cascade
      t.timestamps
    end

    if Nucore::Database.mysql?
      execute "ALTER TABLE sanger_sequencing_samples AUTO_INCREMENT = 11111"
    end

    add_index :sanger_sequencing_samples, :submission_id
  end

  def down
    drop_table :sanger_sequencing_samples
    drop_table :sanger_sequencing_submissions
  end

end
