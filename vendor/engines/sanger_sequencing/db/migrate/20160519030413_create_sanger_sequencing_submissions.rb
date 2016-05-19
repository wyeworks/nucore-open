class CreateSangerSequencingSubmissions < ActiveRecord::Migration

  def up
    create_table :sanger_sequencing_submissions do |t|
      t.integer :order_detail_id
      t.timestamps
    end

    add_index :sanger_sequencing_submissions, :order_detail_id

    create_table :sanger_sequencing_samples do |t|
      t.integer :submission_id, null: false
      t.foreign_key :sanger_sequencing_submissions, column: :submission_id, dependent: :delete, options: "ON UPDATE CASCADE"
      t.timestamps
    end

    add_index :sanger_sequencing_samples, :submission_id
  end

  def down
    drop_table :sanger_sequencing_samples
    drop_table :sanger_sequencing_submissions
  end

end
