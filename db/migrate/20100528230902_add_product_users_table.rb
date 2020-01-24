# frozen_string_literal: true

class AddProductUsersTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table :product_users do |t|
      t.references :product, null: false
      t.integer    :user_id, null: false
      t.integer    :approved_by,   null: false
      t.datetime   :approved_at,   null: false
    end
    execute "ALTER TABLE product_users add CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products (id)"
  end

  def self.down
    drop_table :product_users
  end

end
