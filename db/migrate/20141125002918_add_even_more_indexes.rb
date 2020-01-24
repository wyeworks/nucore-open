# frozen_string_literal: true

class AddEvenMoreIndexes < ActiveRecord::Migration[4.2]

  def change
    add_index :orders, :user_id
    add_index :product_users, :product_access_group_id
    add_index :journals, :facility_id
    add_index :price_group_members, :user_id
  end

end
