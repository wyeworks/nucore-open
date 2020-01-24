# frozen_string_literal: true

class AddOrderDetailToOccupancy < ActiveRecord::Migration[4.2]

  def change
    add_column :secure_rooms_occupancies, :order_detail_id, :integer
    add_index :secure_rooms_occupancies, :order_detail_id
    add_foreign_key :secure_rooms_occupancies, :order_details
  end

end
