# frozen_string_literal: true

class BundleRelatedUpdates < ActiveRecord::Migration[4.2]

  def self.up
    add_column :order_details, :bundle_order_detail_id, :integer, null: true
    execute "ALTER TABLE order_details ADD CONSTRAINT fk_od_bundle_od FOREIGN KEY (bundle_order_detail_id) REFERENCES order_details (id)"
    create_table :bundle_products do |t|
      t.integer :bundle_product_id, null: false
      t.integer :product_id,        null: false
      t.integer :quantity,          null: false
    end
    execute "ALTER TABLE bundle_products ADD CONSTRAINT fk_bundle_prod_prod FOREIGN KEY (bundle_product_id) REFERENCES products (id)"
    execute "ALTER TABLE bundle_products ADD CONSTRAINT fk_bundle_prod_bundle FOREIGN KEY (product_id) REFERENCES products (id)"
  end

  def self.down
    remove_column :order_details, :bundle_order_detail_id
    drop_table :bundle_products
  end

end
