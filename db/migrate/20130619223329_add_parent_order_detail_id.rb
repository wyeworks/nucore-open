# frozen_string_literal: true

class AddParentOrderDetailId < ActiveRecord::Migration[4.2]

  def change
    add_column :order_details, :parent_order_detail_id, :integer, after: :order_id
    add_foreign_key :order_details, :order_details, column: :parent_order_detail_id
  end

end
