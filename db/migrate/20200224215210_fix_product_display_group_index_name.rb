class FixProductDisplayGroupIndexName < ActiveRecord::Migration[5.2]
  def up
    # The name is too long for oracle. This will fix it if the previous migration had already run.
    if index_exists?(:product_display_group_products, [:product_display_group_id, :position], name: "i_product_display_group_position")
      rename_index :product_display_group_products, "i_product_display_group_position", "i_product_display_group_pos"
    end
  end
end
