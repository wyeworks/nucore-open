class CreateProductGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :product_display_groups do |t|
      # 5.1 primary keys are biginteger, while 5.0 are integer, so we need to ensure our types match
      t.references :facility, index: true, foreign_key: true, type: :integer
      t.string :name, null: false
      t.integer :position
      t.timestamps
    end

    create_table :product_display_group_products do |t|
      t.references :product_display_group, index: true, foreign_key: true, null: false
      t.references :product, index: true, foreign_key: true, type: :integer, null: false
      t.timestamps
    end
  end
end
