# frozen_string_literal: true

class AddPriceChangeReasonToOrderDetails < ActiveRecord::Migration[4.2]
  def change
    add_column :order_details, :price_change_reason, :string
    add_column :order_details, :price_changed_by_user_id, :integer

    add_index :order_details, :price_changed_by_user_id
    add_foreign_key :order_details, :users, column: :price_changed_by_user_id
  end
end
