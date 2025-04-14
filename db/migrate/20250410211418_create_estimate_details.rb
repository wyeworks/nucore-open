class CreateEstimateDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :estimate_details do |t|
      t.references :estimate, null: false
      t.references :product, null: false
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
