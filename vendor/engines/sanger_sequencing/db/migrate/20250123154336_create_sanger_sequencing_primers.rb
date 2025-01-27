class CreateSangerSequencingPrimers < ActiveRecord::Migration[7.0]
  def change
    create_table :sanger_sequencing_primers do |t|
      t.string :name

      t.timestamps
    end
  end
end
