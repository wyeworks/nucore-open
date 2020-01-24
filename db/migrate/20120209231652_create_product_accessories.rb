# frozen_string_literal: true

class CreateProductAccessories < ActiveRecord::Migration[4.2]

  def self.up
    create_table :product_accessories do |t|
      t.references  :product,       null: false
      t.integer     :accessory_id,  null: false
    end
  end

  def self.down
    drop_table :product_accessories
  end

end
