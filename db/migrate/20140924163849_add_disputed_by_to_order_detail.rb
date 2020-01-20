# frozen_string_literal: true

class AddDisputedByToOrderDetail < ActiveRecord::Migration[4.2]

  def change
    add_column :order_details, :dispute_by_id, :integer, after: :dispute_at
    add_foreign_key :order_details, :users, column: :dispute_by_id
  end

end
