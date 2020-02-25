class AddDisplayOrderToProductDisplayGroupProducts < ActiveRecord::Migration[5.2]

  def change
    add_column :product_display_group_products, :position, :integer
    add_index :product_display_group_products, [:product_display_group_id, :position], name: "i_product_display_group_pos"
  end

end
