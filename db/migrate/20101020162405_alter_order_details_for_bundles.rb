# frozen_string_literal: true

class AlterOrderDetailsForBundles < ActiveRecord::Migration[4.2]

  def self.up
    add_column    :order_details, :group_id,           :integer, null: true
    add_column    :order_details, :bundle_product_id,  :integer, null: true
    execute "ALTER TABLE order_details ADD CONSTRAINT fk_bundle_prod_id FOREIGN KEY (bundle_product_id) REFERENCES products (id)"
    remove_foreign_key :order_details, name: :fk_od_bundle_od
    remove_column :order_details, :bundle_order_detail_id
  end

  def self.down
    remove_column :order_details, :group_id
    remove_column :order_details, :bundle_product_id
    add_column    :order_details, :bundle_order_detail_id, :integer, null: true
  end

end
