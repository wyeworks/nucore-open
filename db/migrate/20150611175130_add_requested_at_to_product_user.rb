# frozen_string_literal: true

class AddRequestedAtToProductUser < ActiveRecord::Migration[4.2]

  def change
    add_column :product_users, :requested_at, :datetime, null: true
  end

end
