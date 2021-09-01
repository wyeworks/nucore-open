class CreateProductUserImports < ActiveRecord::Migration[5.2]
  def change
    create_table :product_user_imports do |t|
      t.attachment :file
      t.integer :created_by_id, null: false, foreign_key: { to_table: "users" }
      t.references :product, null: false
      t.datetime :processed_at
      t.timestamps
    end
  end
end
