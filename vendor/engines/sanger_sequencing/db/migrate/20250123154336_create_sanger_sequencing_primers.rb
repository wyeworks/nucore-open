class CreateSangerSequencingPrimers < ActiveRecord::Migration[7.0]
  def change
    create_table :sanger_sequencing_primers do |t|
      t.string :name
      t.integer(
        :sanger_product_id,
        null: false,
        index: { name: "i_san_seq_primer_san_prod_idx" }
      )

      t.timestamps
    end
  end
end
