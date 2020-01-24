# frozen_string_literal: true

class AddProductAccessoryToOrderDetail < ActiveRecord::Migration[4.2]

  def change
    add_column :order_details, :product_accessory_id, :integer
    add_foreign_key :order_details, :product_accessories, column: :product_accessory_id
  end

end
